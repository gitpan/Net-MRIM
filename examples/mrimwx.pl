#!/usr/bin/perl
#
# Copyright (c) 2007 Alexandre Aufrere
# Licensed under the terms of the GPL (see perldoc MRIM.pm)
#

use threads;
use threads::shared;
use Wx;
use utf8;
use strict;

my $LOGIN="xxx";
my $PASSWORD="xxx";

# the login dialog...
package MRIMLoginDialog;
use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON);
use base 'Wx::Dialog';

sub new {
	my $class=shift;
	my $self=$class->SUPER::new( undef,           # parent window
                                 -1,              # ID -1 means any
                                 'PerlMRIM::Login',  # title
                                 [-1, -1],        # default position
                                 [300, 200],      # size
                                 );
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $lsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $loginlabel = new Wx::StaticText($self,-1, "Login: ");
	my $enterlogin =  new Wx::TextCtrl($self, 3158,
					"",
					wxDefaultPosition,
					wxDefaultSize
					);
	my $psizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $pwdlabel = new Wx::StaticText($self,-1, "Password: ");
	my $enterpwd =  new Wx::TextCtrl($self, 3159,
					"",
					wxDefaultPosition,
					wxDefaultSize,
					wxTE_PASSWORD
					);
	my $btnlogin = new Wx::Button($self, 3160, "Connect");
	$lsizer->Add($loginlabel,0, wxALL | wxEXPAND, 10);
	$lsizer->Add($enterlogin,0, wxALL | wxEXPAND, 10);
	$psizer->Add($pwdlabel,0, wxALL | wxEXPAND, 10);
	$psizer->Add($enterpwd,0, wxALL | wxEXPAND, 10);	
	$topsizer->Add($lsizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($psizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($btnlogin,0, wxALL | wxEXPAND, 10);
	EVT_BUTTON( $self, $btnlogin, \&OnConnectUser);
	$self->SetSizer($topsizer);
	$self->{_login}=$enterlogin;
	$self->{_pwd}=$enterpwd;
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	return $self;
}

sub OnConnectUser {
	my $dialog=shift;
	$LOGIN=$dialog->{_login}->GetValue();
	$PASSWORD=$dialog->{_pwd}->GetValue();
	$dialog->Destroy();
}

# this is the main class, implemented as Wx::Frame
package MRIMFrame;
use utf8;
use threads;
use threads::shared;
# import the event registration function
use Wx::Event qw(EVT_COMMAND EVT_IDLE EVT_CLOSE EVT_TEXT_ENTER EVT_LISTBOX EVT_BUTTON);
use Wx qw(:everything);
use Net::MRIM;
use Encode;
use base 'Wx::Frame';
my $DONE_EVENT : shared = Wx::NewEventType;
my $LOGOUT_EVENT : shared = Wx::NewEventType;

my $result : shared = 0;
my $data : shared = "";
my @dataout : shared = ();
my @clistkeys : shared = ();
my @clistitems : shared = ();
my @onlinekeys : shared = ();
my @onlineids : shared = ();
my $clistupd : shared = 0;

sub new {
	my $class=shift;
	my $self=$class->SUPER::new( undef,           # parent window
                                 -1,              # ID -1 means any
                                 'PerlMRIM',  # title
                                 [-1, -1],        # default position
                                 [600, 300],      # size
                                 );
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $upsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $btnsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $clist = new Wx::ListBox($self, 3456,
					wxDefaultPosition,
					wxDefaultSize
					);
	my $cwindow = new Wx::TextCtrl($self, 3457,
					"",
					wxDefaultPosition,
					[500,300], 
					wxTE_MULTILINE|wxVSCROLL|wxTE_READONLY
					);
	my $entertext =  new Wx::TextCtrl($self, 3458,
					"",
					wxDefaultPosition,
					wxDefaultSize,
					wxTE_PROCESS_ENTER
					);
	my $btnquit = new Wx::Button($self, 3459, "Quit");
	my $btninfo = new Wx::Button($self, 3460, "Info");
	my $btnadd = new Wx::Button($self, 3461, "Add User");
	my $btndel = new Wx::Button($self, 3462, "Remove User");
	my $btnauth = new Wx::Button($self, 3463, "Authorize User");
	my $status = new Wx::StaticText($self, 3464, "Logged in");
	$upsizer->Add($clist,0,wxEXPAND | wxALL, 10);
	$upsizer->Add($cwindow,0,wxEXPAND | wxALL, 10);
	$btnsizer->Add($btnquit,0,wxEXPAND | wxALL, 10);
	$btnsizer->Add($btninfo,0,wxEXPAND | wxALL, 10);
	$btnsizer->Add($btnadd,0,wxEXPAND | wxALL, 10);
	$btnsizer->Add($btndel,0,wxEXPAND | wxALL, 10);
	$btnsizer->Add($btnauth,0,wxEXPAND | wxALL, 10);
	$btnsizer->Add($status,0,wxEXPAND | wxALL, 10);
	$topsizer->Add($upsizer,0, wxEXPAND | wxALL);
	$topsizer->Add($btnsizer,0, wxEXPAND | wxALL);
	$topsizer->Add($entertext,0, wxALL | wxEXPAND, 10);
	$self->SetSizer($topsizer);
	$self->{_clist}=$clist;
	$self->{_cwindow}=$cwindow;
	$self->{_entertext}=$entertext;
	$self->{_topsizer}=$topsizer;
	$self->{_status}=$status;

	EVT_COMMAND( $self, -1, $DONE_EVENT, \&OnThreadEvent );
	EVT_COMMAND( $self, -1, $LOGOUT_EVENT, \&OnLogoutEvent );
	EVT_TEXT_ENTER( $self, -1, \&OnTextEnter );
	EVT_LISTBOX( $self, -1, \&OnListBoxClicked );
	EVT_BUTTON( $self, $btnquit, \&OnQuit);
	EVT_CLOSE( $self, \&OnQuit);
	EVT_BUTTON( $self, $btninfo, \&OnInfo);
	EVT_BUTTON( $self, $btnadd, \&OnAddUser);
	EVT_BUTTON( $self, $btndel, \&OnDelUser);
	EVT_BUTTON( $self, $btnauth, \&OnAuthUser);

	# here begins the real stuff
	# first, open the login box, and wait for user input
	my $loginDialog = new MRIMLoginDialog();
	$loginDialog->ShowModal();
	# this is quit brutal...
	exit if ($LOGIN eq 'xxx');
	# now start the thread that connects to MRIM
	my $thr = threads->create(\&mrim_conn,$self);
	$self->{_conn}=$thr;

	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	return $self;
}

# this handles the connection through MRIM.pm. It is executed in a separate thread.
sub mrim_conn {
	my $handler=shift;
	my $mrim=Net::MRIM->new(
			PollFrequency => 10,
			Debug => 0
			);
	$mrim->hello();
	if (!$mrim->login($LOGIN,$PASSWORD)) {
		print "LOGIN REJECTED\n";
		exit;
	}
	while(1) {
		my $command;
		my $signal=0;
		my $ret=undef;
		# here we parse commands that was built from interface
		foreach $command (@dataout) {
			if ($command eq "quit") { $mrim->disconnect; return 1; }
			elsif ($command =~ m/^s([0-9]+)\s(.*)/) {
			 	my $contact=$clistkeys[$1-1];
			 	my $cfullname=$clistitems[$1-1];
				my $msg=$2;
				if ($contact ne 'x') {
					$ret=$mrim->send_message($contact,$msg);
					$data.="".my_local_time()." > ".$msg." (to $contact)\n";
					$signal=1;
				} else {
					$data.="".my_local_time()." > ".$msg." (discarded, $cfullname offline)\n";
					$signal=1;
				}
			}
			elsif ($command =~ m/^i([0-9]+)/) {
				my $contact=$clistkeys[$1-1];
				$ret=$mrim->contact_info($contact) if ($contact ne 'x');
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
		$ret=$mrim->ping() if (!defined($ret));
		if ($ret->is_message()) {
			$data.=my_local_time()." ".$ret->get_from()." > ".$ret->get_message()."\n";
			$signal=1;
		} elsif ($ret->is_contact_list()) {
			my $clist=$ret->get_contacts();
	                my $clitem;
			my @nclistkeys=();
			my @nclistitems=();
	                foreach $clitem (keys(%{$clist})) {
				if (defined($clist->{$clitem})) {
		                        push @nclistkeys,$clitem;
		                        push @nclistitems,$clist->{$clitem};
					if(_is_in_list($clitem,@clistkeys)==0) {
						push @clistkeys,$clitem;
						push @clistitems, $clist->{$clitem};
					}
				}
			}
			my $icl;
			for ($icl=0;$icl<scalar(@clistkeys);$icl++) {
				$clitem=$clistkeys[$icl];
				if (_is_in_list($clitem,@nclistkeys)==0) {
					#$data.=my_local_time().': '.$clitem." disconnected.\n" if ($clitem ne 'x');
					$clistkeys[$icl]='x';
				}
			}
			$clistupd = 1;
			$signal=1;
		} elsif ($ret->is_logout_from_server()) {
			my $threvent = new Wx::PlThreadEvent( -1, $LOGOUT_EVENT, $result );
			Wx::PostEvent( $handler, $threvent );
		}
		if ($signal==1) {
			my $threvent = new Wx::PlThreadEvent( -1, $DONE_EVENT, $result );
			Wx::PostEvent( $handler, $threvent );
		}
	}
}

# below are event handlers

sub OnTextEnter {
	my $frame=shift;
	my $input=$frame->{_entertext}->GetValue();
	my @indexes=$frame->{_clist}->GetSelections();
	if (scalar(@indexes)>0) {
		$frame->{_entertext}->Clear();
		push @dataout, "s".$onlineids[$indexes[0]]." ".$input;
		$frame->{_status}->SetLabel("Sending...");
	} else {
		show_error($frame,"No contact selected !");
	}
}

sub OnThreadEvent {
	my( $frame, $event ) = @_;
	Encode::from_to($data,"cp1251","utf8");
	$frame->{_cwindow}->AppendText($data);
	$frame->{_status}->SetLabel("");
	if ($clistupd==1) {
		@onlinekeys=();
		@onlineids=();
		for (my $i=0; $i<scalar(@clistkeys); $i++) {
			my $clitem=$clistkeys[$i];
			my $cllabel=$clistitems[$i];
			Encode::from_to($cllabel,"cp1251","utf8");
			if ($clitem ne 'x') {
				push @onlinekeys, "".$cllabel." ";
				push @onlineids, "".($i+1);
			}
		}
		$frame->{_clist}->Set(\@onlinekeys);
		$frame->{_topsizer}->Fit($frame);
		$frame->{_topsizer}->SetSizeHints($frame);
		$clistupd=0;
	}
	$data="";
}

sub OnListBoxClicked {
	my $frame=shift;
	$frame->{_entertext}->SetFocus();
}

sub OnLogoutEvent {
	my( $frame, $event ) = @_;
	show_error($frame,"Logged out from server !");
	exit;
}

sub OnQuit {
	my $frame=shift;
	$frame->{_status}->SetLabel("Disconnecting....");
	push @dataout,"quit";
	$frame->{_conn}->join();
	exit;
}

sub OnInfo {
	my $frame=shift;
	my @indexes=$frame->{_clist}->GetSelections();
	if (scalar(@indexes)>0) {
		push @dataout, "i".$onlineids[$indexes[0]];
	} else {
		show_error($frame,"No contact selected !");
	}	
}

sub OnAddUser {
	my $frame=shift;
	my $input=$frame->{_entertext}->GetValue();
	if ($input =~ m/\@/) {
		push @dataout,"add ".$input;
	} else {
		show_error($frame,"No user email given !");
	}
}

sub OnDelUser {
	my $frame=shift;
	my $input=$frame->{_entertext}->GetValue();
	if ($input =~ m/\@/) {
		push @dataout,"del ".$input;
	} else {
		show_error($frame,"No user email given !");
	}
}

sub OnAuthUser {
	my $frame=shift;
	my $input=$frame->{_entertext}->GetValue();
	if ($input =~ m/\@/) {
		push @dataout,"auth ".$input;
	} else {
		show_error($frame,"No user email given !");
	}
}

# below are utility methods

sub show_error {
	my ($frame,$msg)=@_;
	my $msgbox=Wx::MessageDialog->new($frame,$msg,"Error",wxICON_ERROR);
	$msgbox->ShowModal();
}

sub my_local_time {
	my @ltime=localtime();
	return sprintf("%02d",$ltime[2]).':'.sprintf("%02d",$ltime[1]);
}

sub _is_in_list {
	my ($item,@list)=@_;
	foreach (@list) {
		return 1 if ($_ eq $item);
	}
	return 0;
} 

# now all the rest: the Wx::App override, and the main part.
package MRIMApp;

use base 'Wx::App';

sub OnInit {
    my $frame = MRIMFrame->new;

    $frame->Show( 1 );
}

package main;
use utf8;
use threads;
use threads::shared;
use Wx;
use Wx::Event qw(EVT_COMMAND EVT_IDLE EVT_CLOSE);
use POSIX qw(locale_h);

setlocale(LC_ALL,'en_US.UTF-8');
my $app = MRIMApp->new;
$app->MainLoop;

exit;
1;
