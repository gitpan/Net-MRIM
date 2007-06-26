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

my $data : shared = "";
my @dataout : shared = ();
my @clistkeys : shared = ();
my @clistitems : shared = ();

my $thr = threads->new(\&mrim_conn);

my $term = new Term::ReadLine 'MRIM';
my $prompt = "MRIM > ";

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
	} 
	elsif ($input eq "help") {
		print <<EOF

MRIM Quick Help

help         - this help
quit         - exits MRIM
sh           - show historized messages waiting
cl           - show contact list
s<num> <msg> - send <msg> to contact number <num> in the contact list

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
	print "\n".$data;
	print "\n" if ($data ne "");
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
		foreach $command (@dataout) {
			if ($command eq "quit") { $mrim->disconnect; exit; }
			 elsif ($command =~ m/^s([0-9]+)\s(.*)/) {
			 	my $contact=$clistkeys[$1-1];
				my $data=$2;
			 	$mrim->send_message($contact,$data);
			 }
		}
		@dataout=();
		sleep(1);
		my $ret=$mrim->ping();
		if ($ret->is_message()) {
			$data.="".$ret->get_from()." > ".$ret->get_message()."\n";
		} elsif ($ret->is_contact_list()) {
			my $clist=$ret->get_contacts();
	                my $clitem;
			@clistkeys=();
			@clistitems=();
	                foreach $clitem (keys(%{$clist})) {
	                        push @clistkeys,$clitem;
				push @clistitems, $clist->{$clitem};
	                }											 
		}
	}

}
