# below is just an utility class
package Net::MRIM::Message;

use constant {
 TYPE_UNKOWN	=> 0,
 TYPE_MSG		=> 1,
 TYPE_LOGOUT_FROM_SRV	=> 2,
 TYPE_CONTACT_LIST	=> 3
 };

sub new {
	my ($pkgname)=@_;
	my $self={}; 
	$self->{_type}=TYPE_UNKOWN;
	bless $self;
	return $self;
}

sub set_message {
	my ($self, $from, $to, $message)=@_;
	$self->{_type}=TYPE_MSG;
	$self->{_from}=$from;
	$self->{_to}=$to;
	$self->{_message}=$message;
}

sub is_message{
	my ($self)=@_;
	return ($self->{_type}==TYPE_MSG);
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

sub set_logout_from_server {
	my ($self)=@_;
	$self->{_type}=TYPE_LOGOUT_FROM_SRV;
}

sub is_logout_from_server {
	my ($self)=@_;
	return ($self->{_type}==TYPE_LOGOUT_FROM_SRV);
}

sub set_contact_list {
	my ($self, $groups, $contacts)=@_;
	$self->{_type}=TYPE_CONTACT_LIST;
	$self->{_groups}=$groups;
	$self->{_contacts}=$contacts;
}

sub is_contact_list {
	my ($self)=@_;
	return ($self->{_type}==TYPE_CONTACT_LIST);
}

sub get_groups {
	my ($self)=@_;
	return $self->{_groups};
}

sub get_contacts {
	my ($self)=@_;
	return $self->{_contacts};
}

package Net::MRIM;

$VERSION='0.4';

=pod

=head1 NAME

Net::MRIM - Perl implementation of mail.ru agent protocol

=head1 DESCRIPTION

This is a Perl implementation of the mail.ru agent protocol, which specs can be found at http://agent.mail.ru/protocol.html

=head1 SYNOPSIS

To construct and connect to MRIM's servers:

 my $mrim=Net::MRIM->new(0);
 $mrim->hello();

To log in:

 if (!$mrim->login("login\@mail.ru","password")) {
	print "LOGIN REJECTED\n";
	exit;
 } else {
	print "LOGGED IN\n";
 }

To add a user:

 $mrim->authorize_user("friend\@mail.ru");

To send a message:

 my $ret=$mrim->send_message("friend\@mail.ru","hello");

Analyze the return of the message:

 if ($ret->is_message()) {
	print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
 }

Looping to get messages:

 while (1) {
	sleep(1);
	$ret=$mrim->ping();
	if ($ret->is_message()) {
		print "From: ".$ret->get_from()." Message: ".$ret->get_message()." \n";
	}
 }

Disconnecting:

 $mrim->disconnect();

=head1 AUTHOR

Alexandre Aufrere <loopkin@nikosoft.net>

=head1 COPYRIGHT

Copyright (c) 2007 Alexandre Aufrere. This code may be used under the terms of the GPL version 2 (see at http://www.gnu.org/copyleft/gpl.html). The protocol remains the property of Mail.Ru (see at http://www.mail.ru).

=cut

use IO::Socket::INET;
use IO::Select;

# the definitions below come straight from the protocol documentation
use constant {
 CS_MAGIC		=> 0xDEADBEEF,
 PROTO_VERSION	=> 0x10009,

 MRIM_CS_HELLO 	=> 0x1001,	## C->S, empty   
 MRIM_CS_HELLO_ACK 	=> 0x1002,	## S->C, UL mrim_connection_params_t

 MRIM_CS_LOGIN2      => 0x1038,	## C->S, LPS login, LPS password, UL status, LPS useragent
 MRIM_CS_LOGIN_ACK 	=> 0x1004,	## S->C, empty
 MRIM_CS_LOGIN_REJ 	=> 0x1005,	## S->C, LPS reason
 MRIM_CS_LOGOUT		=> 0x1013,    ## S->C, UL reason

 MRIM_CS_PING 	=> 0x1006,	## C->S, empty

 MRIM_CS_USER_STATUS	=> 0x100F,	## S->C, UL status, LPS user
  STATUS_OFFLINE	 => 0x00000000,
  STATUS_ONLINE    => 0x00000001,
  STATUS_AWAY      => 0x00000002,

 MRIM_CS_ADD_CONTACT 	=> 0x1019,  # C->S UL flag, UL group_id, LPS email, LPS name
  CONTACT_FLAG_VISIBLE	=> 0x00000008,
 MRIM_CS_AUTHORIZE		=> 0x1020,	# C -> S, LPS user
 MRIM_CS_AUTHORIZE_ACK	=> 0x1021,	# C -> S, LPS user
	
 MRIM_CS_MESSAGE 		=> 0x1008,	## C->S, UL flags, LPS to, LPS message, LPS rtf-message
  MESSAGE_FLAG_NORECV	=> 0x00000004,
  MESSAGE_FLAG_RTF		=> 0x00000080,
  MESSAGE_FLAG_NOTIFY	=> 0x00000400,
 MRIM_CS_MESSAGE_STATUS	=> 0x1012, # S->C
 MRIM_CS_MESSAGE_ACK			=> 0x1009, #S->C
 MRIM_CS_OFFLINE_MESSAGE_ACK	=> 0x101D, #S->C UIDL, LPS message
 MRIM_CS_DELETE_OFFLINE_MESSAGE	=> 0x101E, #C->S UIDL

 MRIM_CS_CONNECTION_PARAMS =>0x1014, # S->C 

 MRIM_CS_CONTACT_LIST2	=> 0x1037, # S->C UL status, UL grp_nb, LPS grp_mask, LPS contacts_mask, grps, contacts

 MRIMUA => "Net::MRIM.pm v. 0.4"
};

# the constructor takes only one optionnal parameter: debug (true or false);
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
	$self->{_ping_period}=30; # value by default
	$self->{_debug}=$debug if ($debug==1);
	bless $self;
	return $self;
}

# this is the technical "hello" header
#  as a side note, it seems to me that this protocol was created by people who were used to e-mail ;-)
sub hello {
	my ($self)=@_;
	my $ret=$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_HELLO,""),0);
	my($msgrcv,$datarcv)=_receive_data($self);
	$datarcv=unpack("V",$datarcv);
	$self->{_ping_period} = $datarcv;
	$self->{_seq_real}++;
	print "DEBUG Connected to MRIM. Ping period is $datarcv\n" if ($datarcv&&($self->{_debug}));
}

# normally useless
sub get_ping_period {
	my ($self)=@_;
	return $self->{_ping_period};
}

# the server should be ping'ed regularly to avoid being disconnected
sub ping {	
	my ($self)=@_;
	print "DEBUG [ping]\n" if ($self->{_debug});
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_PING,""),0);	
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv);
}

# this is to log in...
sub login {
	my ($self,$login,$pass)=@_;
	my $status=STATUS_ONLINE;
	print "DEBUG [status]: $status\n" if ($self->{_debug});
	my $data=_to_lps($login)._to_lps($pass).pack("V",$status)._to_lps(MRIMUA);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_LOGIN2,$data));
	$self->{_seq_real}++;
	$self->{_login}=$login;
	my($msgrcv,$datarcv)=_receive_data($self);
	return ($msgrcv==MRIM_CS_LOGIN_ACK)?1:0;
}

# this is to send a message
sub send_message {
	my ($self,$to,$message)=@_;
	print "DEBUG [send message]: $message\n" if ($self->{_debug});
	my $data=pack("V",MESSAGE_FLAG_NORECV)._to_lps($to)._to_lps($message)._to_lps("");
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_MESSAGE,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv);
}

# to authorize a user to add us to the contact list
sub authorize_user {
	my ($self,$user)=@_;
	my $data=_to_lps($user);
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_AUTHORIZE,$data));
	$self->{_seq_real}++;	
}

# to add a contact to the contact list
# this is still pre-alpha, and there seems to be a mistake in Mail.Ru protocol doc
# as the format of the query is uussss instead of uusss
sub add_contact {
	my ($self, $email, $name)=@_;
	printf("DEBUG [add contact]: $email, $name\n",$msg) if ($self->{_debug});
	my $data=pack("V",CONTACT_FLAG_VISIBLE).pack("V",2)._to_lps($email)._to_lps($name)._to_lps("")._to_lps("");
	print "DEBUG $data\n";
	$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_ADD_CONTACT,$data));
	$self->{_seq_real}++;
	my ($msgrcv,$datarcv)=_receive_data($self);
	return _analyze_received_data($self,$msgrcv,$datarcv);	
}

# and finally to disconnect
sub disconnect {
	my ($self)=@_;
	$self->{_sock}->close;
}

#### private methods below ####

# build the MRIM packet accordingly to the protocol specs
sub _make_mrim_packet {
	my ($self,$msg, $data) = @_;
	my ($magic, $proto, $seq, $from, $fromport) = (CS_MAGIC, PROTO_VERSION, $self->{_seq_real}, 0, 0);
	my $dlen = 0;
	$dlen = length($data) if $data;
	my $mrim_packet = pack("V7", $magic, $proto, $seq, $msg, $dlen, $from, $fromport);
	$mrim_packet.=pack("C[16]",0);
	$mrim_packet .= $data if $data;
	printf("DEBUG [send packet]: MAGIC=$magic, PROTO=$proto, SEQ=$seq, TYP=0x%04x, LEN=$dlen\n",$msg) if ($self->{_debug});
	return $mrim_packet;
}

# retrieve a real host:port, as "mrim.mail.ru" can be several servers
# note that we connect on port 443, as this will always work for sure...
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

# reading the data from server
sub _receive_data {
	my ($self)=@_;
	my $buffer="";
	my $data="";
	my $typ=0;
	printf("DEBUG [recv packet]: waiting for header data\n",$msg) if ($self->{_debug});
	my $s = IO::Select->new();
	$s->add($self->{_sock});
	# this stuff is to not wait for ever data from the server
	# note that we're mixing a bit unbuffered and buffered I/O, this is not 100% great	
	if ($s->can_read(int($self->{_ping_period}/5))) {
		$self->{_sock}->recv($buffer,44);
		my ($magic, $proto, $seq, $msg, $dlen, $from, $fromport, $r1, $r2, $r3, $r4) = unpack ("V11", $buffer);
		$self->{_sock}->recv($buffer,$dlen);
		$data=$buffer;
		$typ=$msg;
		printf("DEBUG [recv packet]: MAGIC=$magic, PROTO=$proto, SEQ=$seq, TYP=0x%04x, LEN=$dlen\n",$msg) if ($self->{_debug});
	}
	return ($typ,$data);	
}

# the packet analyzer
sub _analyze_received_data {
	my ($self,$msgrcv,$datarcv)=@_;
	my $data=new Net::MRIM::Message();
	if ($msgrcv==MRIM_CS_OFFLINE_MESSAGE_ACK) {
		$data->set_message("OFFLINE",$self->{_login},substr($datarcv,8,-1));
		$self->{_sock}->send(_make_mrim_packet($self,MRIM_CS_DELETE_OFFLINE_MESSAGE,substr($datarcv,0,8)));
	} elsif ($msgrcv==MRIM_CS_MESSAGE_ACK) {
		my @datas=_from_mrim_us("uuss",$datarcv);
		# below is a work-around: it seems that sometimes message_flag is left to 0...
		if (($datas[1]==MESSAGE_FLAG_NORECV)||($datas[1]==MESSAGE_FLAG_RTF)||$datas[1]==0) {
			$data->set_message($datas[2],$self->{_login},$datas[3]);
		}
	} elsif ($msgrcv==MRIM_CS_LOGOUT) {
		$data->set_logout_from_server();
	} elsif ($msgrcv==MRIM_CS_CONTACT_LIST2) {
		# S->C UL status, UL grp_nb, LPS grp_mask, LPS contacts_mask, grps, contacts
		my @datas=_from_mrim_us("uuss",$datarcv);
		my $nb_groups=$datas[1];
		my $gr_mask=$datas[2];
		my $ct_mask=$datas[3];
		print "DEBUG: found $datas[1] groups, $datas[2] gr mask, $datas[3] contact mask\n" if ($self->{_debug});
		$datarcv=$datas[4];
		my $groups={};
		for (my $i=0; $i<$nb_groups; $i++) {
			my ($grp_id,$grp_name)=(0,"");
			($grp_id,$grp_name,$datarcv)=_from_mrim_us($gr_mask,$datarcv);
			print "DEBUG: Found group $grp_name of id $grp_id\n" if ($self->{_debug});
			$groups->{$grp_id}=$grp_name;
		}
		my $contacts={};
		while (length($datarcv)>1) {
			# TODO works only with current pattern uussuus . if it changes, will break...
			my ($flags,$group, $email, $name, $sflags, $status, $unk)=(0,"");
			($flags,$group, $email, $name, $sflags, $status, $unk, $datarcv)=_from_mrim_us($ct_mask,$datarcv);
			print "DEBUG: Found contact $name of id $email unknown: $unk\n" if ($self->{_debug});
			$contacts->{$email}=$name;
		}
		$data->set_contact_list($groups,$contacts);
	} else {
		$data->set_message("DEBUG",$self->{_login},$datarcv) if ($self->{_debug});
	}
	return $data;
}

sub _from_mrim_us {
	my ($pattern,$data)=@_;
	my @res=();
	for (my $i=0;$i<length($pattern);$i++) {
		my $datatype=substr($pattern,$i,1);
		if ($datatype eq 'u') {
			$data=~m/^(\C\C\C\C)(.*)/;
			my $item=unpack("V",$1);
			$data=$2;
			push @res,$item;
		} elsif ($datatype eq 's') {
			$data=~m/^(\C\C\C\C)(.*)/;
			my $itemlength=unpack("V",$1);
			$data=$2;
			$data=~m/^(.{$itemlength})(.*)/;
			my $item=$1;
			$data=$2;
			push @res,$item;
		}
	}
	push @res,$data;
	return @res;
}

# convert to LPV (read the protocol !)
sub _to_lps {
	my ($str)=@_;
	return pack("V",length($str)).$str;
}

return 1;
