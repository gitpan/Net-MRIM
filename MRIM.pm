# below is just an utility class
package Net::MRIM::Message;

my $TYPE_UNKOWN=0;
my $TYPE_MSG=1;

sub new {
	my ($pkgname)=@_;
	my $self={}; 
	$self->{_type}=$TYPE_UNKOWN;
	bless $self;
	return $self;
}

sub set_message {
	my ($self, $from, $to, $message)=@_;
	$self->{_type}=$TYPE_MSG;
	$self->{_from}=$from;
	$self->{_to}=$to;
	$self->{_message}=$message;
}

sub is_message{
	my ($self)=@_;
	return ($self->{_type}==$TYPE_MSG);
}

sub get_from {
	my ($self)=@_;
	return $self->{_from};
}

sub get_to {
	my ($self)=@_;
	return $self->{_to};
}

sub get_message {
	my ($self)=@_;
	return $self->{_message};
}

package Net::MRIM;

$VERSION='0.2';

=pod

=head1 NAME

Net::MRIM - Perl implementation of mail.ru agent protocol

=head1 DESCRIPTION

This is a Perl implementation of the mail.ru agent protocol, which specs can be found at http://agent.mail.ru/protocol.html

=head1 SYNOPSIS

my $mrim=Net::MRIM->new(0);
$mrim->hello();

if (!$mrim->login("login\@mail.ru","password")) {

	print "LOGIN REJECTED\n";
	exit;
} else {
	print "LOGGED IN\n";
}

$mrim->authorize_user("friend\@mail.ru");

my $ret=$mrim->send_message("friend\@mail.ru","hello");

if ($ret->is_message()) {

	print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
}

while (1) {

	sleep(1);
	$ret=$mrim->ping();
	
	if ($ret->is_message()) {
		print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
	}
}

$mrim->disconnect();

=head1 AUTHOR

Alexandre Aufrere <loopkin@nikosoft.net>

=cut

use IO::Socket::INET;

my $CS_MAGIC		= 0xDEADBEEF;
my $PROTO_VERSION	= 0x10009;

my $MRIM_CS_HELLO 	= 0x1001;	## C->S, empty   
my $MRIM_CS_HELLO_ACK 	= 0x1002;	## S->C, UL mrim_connection_params_t

my $MRIM_CS_LOGIN2      = 0x1038;	## C->S, LPS login, LPS password, UL status, LPS useragent
my $MRIM_CS_LOGIN_ACK 	= 0x1004;	## S->C, empty
my $MRIM_CS_LOGIN_REJ 	= 0x1005;	## S->C, LPS reason

my $MRIM_CS_PING 	= 0x1006;	## C->S, empty

my $MRIM_CS_USER_STATUS	= 0x100F;	## S->C, UL status, LPS user
my $STATUS_OFFLINE	 = 0x00000000;
my $STATUS_ONLINE    = 0x00000001;
my $STATUS_AWAY      = 0x00000002;

my $MRIM_CS_AUTHORIZE=	0x1020;	# C -> S, LPS user
my $MRIM_CS_AUTHORIZE_ACK=	0x1021;	# C -> S, LPS user
	
my $MRIM_CS_MESSAGE 	= 0x1008;	## C->S, UL flags, LPS to, LPS message, LPS rtf-message
my $MESSAGE_FLAG_NORECV = 0x00000004;
my $MESSAGE_FLAG_RTF	= 0x00000080;
my $MESSAGE_FLAG_NOTIFY	= 0x00000400;
my $MRIM_CS_MESSAGE_STATUS	= 0x1012; # S->C
my $MRIM_CS_MESSAGE_ACK		= 0x1009; #S->C
my $MRIM_CS_OFFLINE_MESSAGE_ACK = 0x101D; #S->C

my $MRIM_CS_CONNECTION_PARAMS =0x1014; # S->C

my $MRIMUA="MRIM.pm v. $VERSION";

sub new {
	my ($pkgname,$debug)=@_;
	my ($host, $port) = _get_host_port();
	my $sock = IO::Socket::INET->new(
                PeerAddr		=> $host,
                PeerPort		=> $port,
                Proto			=> 'tcp',
				TimeOut			=> 10
			);
	die "couldn't connect" if (!defined($sock));
	print "DEBUG Connected to $host:$port\n" if ($debug==1);
	my $self={};
	$self->{_sock}=$sock;
	$self->{_seq_real}=0;
	$self->{_debug}=$debug if ($debug==1);
	bless $self;
	return $self;
}

sub hello {
	my ($self)=@_;
	my $ret=$self->{_sock}->send(_make_mrim_packet($self,$MRIM_CS_HELLO,""),0);
	my($msgrcv,$datarcv)=_receive_data($self);
	$datarcv=unpack("V",$datarcv);
	$self->{_ping_period} = $datarcv;
	$self->{_seq_real}++;
	print "DEBUG Connected to MRIM. Ping period is $datarcv\n" if ($datarcv&&($self->{_debug}));
}

sub get_ping_period {
	my ($self)=@_;
	return $self->{_ping_period};
}

sub ping {	
	my ($self)=@_;
	print "DEBUG [ping]\n" if ($self->{_debug});
	$self->{_sock}->send(_make_mrim_packet($self,$MRIM_CS_PING,""),0);	
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv)=_receive_data($self);
	return _analyze_received_data($msgrcv,$datarcv);
}

sub login {
	my ($self,$login,$pass)=@_;
	my $status=$STATUS_ONLINE;
	print "DEBUG [status]: $status\n" if ($self->{_debug});
	my $data=_to_lpv($login)._to_lpv($pass).pack("V",$status)._to_lpv($MRIMUA);
	$self->{_sock}->send(_make_mrim_packet($self,$MRIM_CS_LOGIN2,$data));
	$self->{_seq_real}++;
	my($msgrcv,$datarcv)=_receive_data($self);
	return ($msgrcv==$MRIM_CS_LOGIN_ACK)?1:0;
}

sub send_message {
	my ($self,$to,$message)=@_;
	print "DEBUG [send message]: $message\n" if ($self->{_debug});
	my $data=pack("V",$MESSAGE_FLAG_NORECV)._to_lpv($to)._to_lpv($message)._to_lpv("");
	$self->{_sock}->send(_make_mrim_packet($self,$MRIM_CS_MESSAGE,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv)=_receive_data($self);
	return _analyze_received_data($msgrcv,$datarcv);
}

sub authorize_user {
	my ($self,$user)=@_;
	my $data=_to_lpv($user);
	$self->{_sock}->send(_make_mrim_packet($self,$MRIM_CS_AUTHORIZE,$data));
	$self->{_seq_real}++;	
}

sub disconnect {
	my ($self)=@_;
	$self->{_sock}->close;
}

# private methods below

sub _make_mrim_packet {
	my ($self,$msg, $data) = @_;
	my ($magic, $proto, $seq, $from, $fromport) = ($CS_MAGIC, $PROTO_VERSION, $self->{_seq_real}, 0, 0);
	my $dlen = 0;
	$dlen = length($data) if $data;
	my $mrim_packet = pack("V7", $magic, $proto, $seq, $msg, $dlen, $from, $fromport);
	$mrim_packet.=pack("C[16]",0);
	$mrim_packet .= $data if $data;
	printf("DEBUG [send packet]: MAGIC=$magic, PROTO=$proto, SEQ=$seq, TYP=0x%04x, LEN=$dlen\n",$msg) if ($self->{_debug});
	return $mrim_packet;
}

sub _get_host_port {	
	my $sock = new IO::Socket::INET (		
			PeerAddr  => 'mrim.mail.ru',		
			PeerPort  => 443,		
			PeerProto => 'tcp', 		
			TimeOut   => 10	);
	my $data="";
	$sock->recv($data, 18);	
	close $sock;	
	chomp $data;
   	return split /:/,  $data;	
}

sub _receive_data {
	my ($self)=@_;
	my $buffer="";
	$self->{_sock}->recv($buffer,44);
	my ($magic, $proto, $seq, $msg, $dlen, $from, $fromport, $r1, $r2, $r3, $r4) = unpack ("V11", $buffer);
	$self->{_sock}->recv($buffer,$dlen);
	my $data=$buffer;
	printf("DEBUG [recv packet]: MAGIC=$magic, PROTO=$proto, SEQ=$seq, TYP=0x%04x, LEN=$dlen\n",$msg) if ($self->{_debug});
	return ($msg,$data);	
}

sub _analyze_received_data {
	my ($msgrcv,$datarcv)=@_;
	my $data=new Net::MRIM::Message();
	if ($msgrcv==$MRIM_CS_OFFLINE_MESSAGE_ACK) {
		$data->set_message("","",substr($datarcv,8,-1));
	} elsif ($msgrcv==$MRIM_CS_MESSAGE_ACK) {
		$datarcv=~ m/^(\C\C\C\C)(\C\C\C\C)(\C\C\C\C)(.*)/;
		my $msg_id=$1;
		my $flags=$2;
		my $flen=$3;
		$datarcv=$4;
		$msg_id=unpack("V",$msg_id);
		$flags=unpack("V",$flags);
		$flen=unpack("V",$flen);
		$datarcv=~m/^(.{$flen})(\C\C\C\C)(.*)/;
		my $from = $1;
		my $mlen=$2;
		$datarcv=$3;
		$mlen=unpack("V",$mlen);
		$datarcv=~m/^(.{$mlen})(\C\C\C\C)(.*)/;
		my $msg=$1;
		if (($flags==$MESSAGE_FLAG_NORECV)||($flags==$MESSAGE_FLAG_RTF)) {
			$data->set_message($from,"",$msg);
		}
	}
	return $data;
}

sub _to_lpv {
	my ($str)=@_;
	return pack("V",length($str)).$str;
}

return 1;