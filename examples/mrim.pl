#!/usr/bin/perl -w
#
# Copyright (c) 2007 Alexandre Aufrere
# Licensed under the terms of the GPL (see perldoc MRIM.pm)

use strict;
use Net::MRIM;
use threads;
use threads::shared;
use Term::ReadLine;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

#
#  Enter login information below !
#

my $LOGIN = "login\@mail.ru";
my $PASSWORD = "password";

#
# the real stuff starts here...
#

$|=1;

my $data : shared = "";
my @dataout : shared = ();
my @clistkeys : shared = ();
my @clistitems : shared = ();

my $thr = threads->new(\&mrim_conn);

my $term = new Term::ReadLine 'MRIM';
my $prompt : shared = "MRIM > ";

my $input="";

while ($input=$term->readline($prompt)) {
	if ($input eq "quit") { cleanup_exit(); }
	elsif ($input eq "sh") { flush_data(); } 
	elsif ($input eq "cl") {
		print BOLD "\n## Contact List ##\n";
		for (my $i=0; $i<scalar(@clistkeys); $i++) {
			print "".($i+1)." : ".$clistkeys[$i]." (".$clistitems[$i].")\n";
		}
		print "##\n";
		flush_data();
	}
	elsif ($input =~ m/^s[0-9]+.*/) {
		push @dataout,$input;
		flush_data();
	} elsif ($input=~m/^add\s.*/) {
		push @dataout,$input;
		flush_data();
	} elsif ($input=~m/^del\s.*/) {
		push @dataout,$input;
		flush_data();
	}
	elsif ($input=~m/^auth\s.*/) {
		push @dataout,$input;
		flush_data();
	}
	elsif ($input eq "help") {
		print <<EOF

MRIM Quick Help

help         - this help
quit         - exits MRIM
sh           - show historized messages waiting
cl           - show contact list
s<num> <msg> - send <msg> to contact number <num> in the contact list
add <email>  - add an user to the contact list
del <email>  - remove an user from the contact list

EOF
	}
	else {
		print BOLD RED "\nunkown command $input\n";
		print "\n";
	}

}

print "Exiting...\n"; push @dataout,"quit"; $thr->join; exit;

exit;

sub flush_data {
	print RESET "\n".$data;
	print UNDERLINE "\nMRIM > " if (length($data)>1);
	$data="";
}

sub cleanup_exit {
	flush_data();
	print BOLD "Exiting...";
	print "\n";
	push @dataout,"quit"; 
	$thr->join;
	exit;
}



sub mrim_conn {

	my $mrim=Net::MRIM->new(0);
	$mrim->hello();
	if (!$mrim->login($LOGIN,$PASSWORD)) {
		print "LOGIN REJECTED\n";
		exit;
	}

	while (1) {
		my $command;
		my $ret=undef;
		foreach $command (@dataout) {
			if ($command eq "quit") { $mrim->disconnect; exit; }
			elsif ($command =~ m/^s([0-9]+)\s(.*)/) {
			 	my $contact=$clistkeys[$1-1];
				my $data=$2;
			 	$ret=$mrim->send_message($contact,$data);
			}
			elsif ($command =~ m/^add\s(.*)/) {
				$ret=$mrim->add_contact($1);
			}
			elsif ($command =~ m/^del\s(.*)/) {
				$ret=$mrim->remove_contact($1);
			}
			elsif ($command =~ m/^auth\s(.*)/) {
				$mrim->authorize_user($1);
			}
		}
		@dataout=();
		#sleep(1);
		$ret=$mrim->ping() if (!defined($ret));
		if ($ret->is_message()) {
			$data.="".$ret->get_from()." > ".$ret->get_message()."\n";
			flush_data();
		} elsif ($ret->is_contact_list()) {
			my $clist=$ret->get_contacts();
	                my $clitem;
			@clistkeys=();
			@clistitems=();
	                foreach $clitem (keys(%{$clist})) {
				if (defined($clist->{$clitem})) {
		                        push @clistkeys,$clitem;
					push @clistitems, $clist->{$clitem};
				}
	                }											 
		} elsif ($ret->is_logout_from_server()) {
			print "LOGGED OUT FROM SERVER\n";
			exit;
		}
	}

}