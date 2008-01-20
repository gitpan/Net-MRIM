#!/usr/bin/perl

#
# $Date: 2008-01-20 18:27:03 $
#
# Copyright (c) 2007-2008 Alexandre Aufrere
# Licensed under the terms of the GPL (see perldoc MRIM.pm)
#

use threads;
use threads::shared;
use Wx;
use utf8;
use strict;

## Configuration ##

# Number of lines of history to save
my $LAST_HISTORY_LINES=50;
# Display nickname (1) or username (0) in contact list
my $DISPLAY_NICK=0;
# before wxPerl version 0.8, notification isn't really nice, so you can deactivate here below
# after version 0.80 it just works, and cannot be disabled.
my $NOTIFY=1;

##                     ##
## DO NOT MODIFY BELOW ##
##                     ##
my $LOGIN="xxx";
my $PASSWORD="xxx";
my $VERSION='0.7';
my @TRNS=('0');
my $TLANG='';

my @datain : shared = ();
my @datatypein : shared = ();
my @dataout : shared = ();

# the login dialog...
package MRIMLoginDialog;
use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON EVT_TEXT_ENTER);
use base 'Wx::Dialog';

sub new {
	my $class=shift;
	my $self=$class->SUPER::new( undef,
                                 -1,
                                 'PerlMRIM::Login',
                                 [-1, -1],        # default position
                                 [300, 200],      # size
                                 );
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $lsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $loginlabel = new Wx::StaticText($self,-1, t::t("Login").": ");
	my $enterlogin =  new Wx::TextCtrl($self, 3158,
					"",
					wxDefaultPosition,
					wxDefaultSize
					);
	my $psizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $pwdlabel = new Wx::StaticText($self,-1, t::t("Password").": ");
	my $enterpwd =  new Wx::TextCtrl($self, 3159,
					"",
					wxDefaultPosition,
					wxDefaultSize,
					wxTE_PASSWORD|wxTE_PROCESS_ENTER
					);
	my $btnlogin = new Wx::Button($self, 3160, t::t("Connect"));
	$lsizer->Add($loginlabel,0, wxALL | wxEXPAND, 10);
	$lsizer->Add($enterlogin,0, wxALL | wxEXPAND, 10);
	$psizer->Add($pwdlabel,0, wxALL | wxEXPAND, 10);
	$psizer->Add($enterpwd,0, wxALL | wxEXPAND, 10);	
	$topsizer->Add($lsizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($psizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($btnlogin,0, wxALL | wxEXPAND, 10);
	EVT_BUTTON( $self, $btnlogin, \&OnConnectUser);
	EVT_TEXT_ENTER( $self, -1, \&OnConnectUser );
	EVT_CLOSE( $self, \&OnQuit);
	$self->SetSizer($topsizer);
	$self->{_login}=$enterlogin;
	$self->{_pwd}=$enterpwd;
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	$self->Centre(wxBOTH);
	return $self;
}

sub OnConnectUser {
	my $dialog=shift;
	$LOGIN=$dialog->{_login}->GetValue();
	$PASSWORD=$dialog->{_pwd}->GetValue();
	$dialog->Destroy();
}

sub OnQuit {
	exit;
}

# the info dialog...
package MRIMInfoDialog;
use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON EVT_TEXT_ENTER);
use Wx::Html;
use base 'Wx::Dialog';

sub new {
	my ($class,$msg)=@_;
	my $self=$class->SUPER::new( undef,
                                 -1,
                                 'PerlMRIM::Information',
                                 [-1, -1],        # default position
                                 [300, 200],      # size
                                 );
	Wx::Image::AddHandler(new Wx::JPEGHandler());
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $mwindow = new Wx::HtmlWindow($self, -1,					
					wxDefaultPosition,
					[500,300]);
	my $btnok = new Wx::Button($self, -1, t::t("Ok"));
	$mwindow->AppendToPage("<html><body>$msg</body></html>");
	$topsizer->Add($mwindow,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($btnok,0, wxALL | wxEXPAND, 10);
	EVT_BUTTON( $self, $btnok, \&OnOk);
	$self->SetSizer($topsizer);
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	$self->Centre(wxBOTH);
	return $self;
}

sub OnOk {
	my $dialog=shift;
	$dialog->Destroy();
}

# the input dialog...
package MRIMInputDialog;
use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON EVT_TEXT_ENTER);
use base 'Wx::Dialog';

sub new {
	my ($class,$msg,$preinput)=@_;
	my $self=$class->SUPER::new( undef,
                                 -1,
                                 'PerlMRIM::Input',
                                 [-1, -1],        # default position
                                 [300, 200],      # size
                                 );
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $msglabel = new Wx::StaticText($self,-1, "$msg");
	my $mwindow = new Wx::TextCtrl($self, -1,
					"$preinput",
					wxDefaultPosition,
					wxDefaultSize, 
					wxTE_PROCESS_ENTER
					);
	my $bsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $btnok = new Wx::Button($self, -1, t::t("Ok"));
	my $btncancel = new Wx::Button($self, -1, t::t("Cancel"));
	$bsizer->Add($btncancel,0, wxALL | wxEXPAND, 10);	
	$bsizer->Add($btnok,0, wxALL | wxEXPAND, 10);	
	$topsizer->Add($msglabel,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($mwindow,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($bsizer,0, wxALL | wxEXPAND, 10);
	EVT_BUTTON( $self, $btnok, \&OnOk);
	EVT_BUTTON( $self, $btncancel, \&OnCancel);
	EVT_TEXT_ENTER( $self, -1, \&OnOk);
	$self->SetSizer($topsizer);
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	$self->Centre(wxBOTH);
	$self->{_value}='';
	$self->{_valuectrl}=$mwindow;
	return $self;
}

sub OnOk {
	my $dialog=shift;
	$dialog->{_value}=$dialog->{_valuectrl}->GetValue();
	$dialog->Destroy();
}

# cancel button event handler
sub OnCancel {
	my $dialog=shift;
	$dialog->{_value}='';
	$dialog->Destroy();
}

sub getValue {
	my $self=shift;
	return $self->{_value};
}

# the info dialog...
package MRIMNotifyDialog;
use Wx qw(:everything);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON EVT_TEXT_ENTER);
use Wx::Html;
use base 'Wx::Dialog';

sub new {
	my ($class,$msg,$ntype,$nvalue)=@_;
	# ntype 0 : small text notification (for mail notification)
	# ntype 1 : big text notification with small chars (for offline messages)
	# ntype 2 : authorize notification, requires nvalue
	my ($x,$y)=(Wx::GetDisplaySize()->GetWidth(),Wx::GetDisplaySize()->GetHeight());
	my $big=0;
	$big=1 if ($ntype!=0);
	$x-=(250+(80*$big));
	$y-=(250+(80*$big));
	my $self=$class->SUPER::new( undef,
                                 -1,
                                 'PerlMRIM::Notify',
                                 [$x, $y],        # default position
                                 [200, 100],      # size
                                 wxCAPTION|wxSTAY_ON_TOP);
	Wx::Image::AddHandler(new Wx::JPEGHandler());
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $mwindow = new Wx::HtmlWindow($self, -1,					
					wxDefaultPosition,
					[200+(80*$big),100+(80*$big)]);
	my $btnok = new Wx::Button($self, -1, t::t("Ok"),wxDefaultPosition,wxDefaultSize,wxNO_BORDER);
	my $color='#F26D00';
	$color='#FFFFFF' if ($big==1);
	$mwindow->AppendToPage("<html><body bgcolor='#00468C' text='$color'>$msg</body></html>");
	$topsizer->Add($mwindow,0, wxALL | wxEXPAND, 10);
	EVT_BUTTON( $self, $btnok, \&OnOk);
	if ($ntype==2) {
		my $btnauth=new Wx::Button($self, -1, t::t("Authorize"),wxDefaultPosition,wxDefaultSize,wxNO_BORDER);
		$topsizer->Add($btnauth,0, wxALL | wxEXPAND, 10);
		EVT_BUTTON( $self, $btnauth, \&OnAuth);
		$self->{_mailToAuth}=$nvalue;
		$self->{_mailAuth}='';
	}
	$topsizer->Add($btnok,0, wxALL | wxEXPAND, 10);
	$self->SetSizer($topsizer);
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	return $self;
}

# Ok event handler
sub OnOk {
	my $dialog=shift;
	$dialog->Destroy();
}

# auth event handler: launches auth dialog
sub OnAuth {
	my $dialog=shift;
	my $inputDialog = new MRIMInputDialog(t::t('Enter email of the user to authorize:'),$dialog->{_mailToAuth});
	$inputDialog->ShowModal();
	$dialog->{_mailAuth}=$inputDialog->getValue();
	# this is ugly...
	if ($dialog->{_mailAuth} ne '') {
		push @dataout,"auth ".$dialog->{_mailAuth};
	}
	$dialog->Destroy();
}

# the search dialog...
package MRIMSearchDialog;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON EVT_TEXT_ENTER);
use base 'Wx::Dialog';
use Net::MRIM::Data;

sub new {
	my $class=shift;
	my $self=$class->SUPER::new( undef,
                                 -1,
                                 'PerlMRIM::Search',
                                 [-1, -1],        # default position
                                 [300, 200],      # size
                                 );
	my $topsizer = new Wx::BoxSizer(wxVERTICAL);
	my $nsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $nicknamelabel = new Wx::StaticText($self,-1, t::t("Email").": ");
	my $enternickname =  new Wx::TextCtrl($self, 3058,
					"",
					wxDefaultPosition,
					wxDefaultSize,
					wxTE_PROCESS_ENTER
					);
	my $ssizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $slabel = new Wx::StaticText($self,-1, t::t("Sex").": ");
	my $choosesex = new Wx::Choice($self, 3059,
					wxDefaultPosition,
					wxDefaultSize,
					['',t::t('Male'),t::t('Female')]
					);
	my $csizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $clabel = new Wx::StaticText($self, -1, t::t("Country").": ");
	my $choosecountry = new Wx::ComboBox($self, 3060,
					"",
					wxDefaultPosition,
					wxDefaultSize,
					[''],
					wxCB_DROPDOWN|wxCB_READONLY
					);
	my @countries=keys(%Net::MRIM::Data::COUNTRIES);
	@countries=sort(@countries);
	foreach my $country (@countries) {
			$choosecountry->Append($country);
	}
	my $osizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $olabel = new Wx::StaticText($self, -1, t::t("Online").": ");
	my $checkonline = new Wx::CheckBox($self, 3061, 
					t::t('Check to search only online users'),
					wxDefaultPosition,
					wxDefaultSize);
	my $bsizer = new Wx::BoxSizer(wxHORIZONTAL);
	my $btnsearch = new Wx::Button($self, 3062, t::t("Search"));
	my $btncancel = new Wx::Button($self, 3063, t::t("Cancel"));
	$nsizer->Add($nicknamelabel,0, wxALL | wxEXPAND, 10);
	$nsizer->Add($enternickname,0, wxALL | wxEXPAND, 10);
	$ssizer->Add($slabel,0, wxALL | wxEXPAND, 10);
	$ssizer->Add($choosesex,0, wxALL | wxEXPAND, 10);	
	$csizer->Add($clabel,0, wxALL | wxEXPAND, 10);	
	$csizer->Add($choosecountry,0, wxALL | wxEXPAND, 10);	
	$osizer->Add($olabel,0, wxALL | wxEXPAND, 10);	
	$osizer->Add($checkonline,0, wxALL | wxEXPAND, 10);	
	$bsizer->Add($btncancel,0, wxALL | wxEXPAND, 10);	
	$bsizer->Add($btnsearch,0, wxALL | wxEXPAND, 10);	
	$topsizer->Add($nsizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($ssizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($csizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($osizer,0, wxALL | wxEXPAND, 10);
	$topsizer->Add($bsizer,0, wxALL | wxEXPAND, 10);
	EVT_BUTTON( $self, $btnsearch, \&OnSearchUser);
	EVT_BUTTON( $self, $btncancel, \&OnCancel);
	EVT_TEXT_ENTER( $self, -1, \&OnSearchUser );
	$self->SetSizer($topsizer);
	$self->{_email}='';
	$self->{_emailctrl}=$enternickname;
	$self->{_sex}=0;
	$self->{_sexctrl}=$choosesex;
	$self->{_country}='';
	$self->{_countryctrl}=$choosecountry;
	$self->{_online}=0;
	$self->{_onlinectrl}=$checkonline;
	$self->{_cancelled}=1;
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	$self->Centre(wxBOTH);
	return $self;
}

# search button event handler
sub OnSearchUser {
	my $dialog=shift;
	$dialog->{_cancelled}=0;
	$dialog->{_email}=$dialog->{_emailctrl}->GetValue();
	$dialog->{_sex}=$dialog->{_sexctrl}->GetSelection();
	$dialog->{_country}=$Net::MRIM::Data::COUNTRIES{$dialog->{_countryctrl}->GetValue()};
	$dialog->{_online}=$dialog->{_onlinectrl}->GetValue();
	$dialog->Destroy();
}

# cancel button event handler
sub OnCancel {
	my $dialog=shift;
	$dialog->Destroy();
}

# below are assessors
sub getEmail {
	my $self=shift;
	return $self->{_email};
}

sub getSex {
	my $self=shift;
	return $self->{_sex};
}

sub getCountry {
	my $self=shift;
	return $self->{_country};
}

sub getOnline {
	my $self=shift;
	return ($self->{_online}||0);
}

sub getCancelled {
	my $self=shift;
	return $self->{_cancelled};
}

# this is the main window class, implemented as Wx::Frame
package MRIMFrame;
use utf8;
use threads;
use threads::shared;
# import the event registration function
use Wx::Event qw(EVT_COMMAND EVT_IDLE EVT_CLOSE EVT_TEXT_ENTER EVT_LISTBOX EVT_BUTTON EVT_MENU);
use Wx qw(:everything);
use Net::MRIM;
use Encode;
use base 'Wx::Frame';
my $DONE_EVENT : shared = Wx::NewEventType;
my $LOGOUT_EVENT : shared = Wx::NewEventType;

my $result : shared = 0;
my @clistkeys : shared = ();
my @clistitems : shared = ();
my @onlinekeys : shared = ();
my @onlinemails : shared = ();
my @onlineids : shared = ();
my $clistupd : shared = 0;

sub new {
	my $class=shift;
	my $self=$class->SUPER::new( undef,
                                 -1,              
                                 'PerlMRIM',
                                 [-1, -1],		# default position
                                 [600, 300],	# size
                                 wxMINIMIZE_BOX | wxSYSTEM_MENU | wxCAPTION | wxCLOSE_BOX | wxCLIP_CHILDREN);
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
	my $btninfo = new Wx::Button($self, 3460, t::t("Info"));
	my $btnadd = new Wx::Button($self, 3461, t::t("Add User"));
	my $btndel = new Wx::Button($self, 3462, t::t("Remove"));
	my $btnauth = new Wx::Button($self, 3463, t::t("Authorize"));
	my $status = new Wx::StaticText($self, 3465, t::t("Logging in..."));
	$upsizer->Add($clist,0,wxEXPAND | wxALL, 10);
	$upsizer->Add($cwindow,0,wxEXPAND | wxALL, 10);
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

	my $actionMenu = new Wx::Menu();
	$actionMenu->Append(3504,t::t("&Search People..."));
	$actionMenu->AppendSeparator();	$actionMenu->Append(3505,t::t("&Quit"));
	my $helpMenu = new Wx::Menu();
	$helpMenu->Append(3506,t::t("&Check for Updates..."));
	$helpMenu->Append(3507,t::t("&About..."));
	my $menuBar = new Wx::MenuBar();
	$menuBar->Append($actionMenu,t::t("&Action"));
	$menuBar->Append($helpMenu,t::t("&Help"));
	$self->SetMenuBar($menuBar);
	
	EVT_COMMAND( $self, -1, $DONE_EVENT, \&OnThreadEvent );
	EVT_COMMAND( $self, -1, $LOGOUT_EVENT, \&OnLogoutEvent );
	EVT_TEXT_ENTER( $self, -1, \&OnTextEnter );
	EVT_LISTBOX( $self, -1, \&OnListBoxClicked );
	EVT_BUTTON( $self, $btninfo, \&OnInfo);
	EVT_BUTTON( $self, $btnadd, \&OnAddUser);
	EVT_BUTTON( $self, $btndel, \&OnDelUser);
	EVT_BUTTON( $self, $btnauth, \&OnAuthUser);
	EVT_MENU( $self, 3504, \&OnSearchUser);
	EVT_MENU( $self, 3505, \&OnQuit);
	EVT_CLOSE( $self, \&OnQuit);
	EVT_MENU( $self, 3506, \&OnCheckUpdate);
	EVT_MENU( $self, 3507, \&OnAbout);

	# here begins the real stuff
	# first, open the login box, and wait for user input
	my $loginDialog = new MRIMLoginDialog();
	$loginDialog->ShowModal();
	# this is quite brutal...
	exit if ($LOGIN eq 'xxx');
	# now start the thread that connects to MRIM
	my $thr = threads->create(\&mrim_conn,$self);
	$self->{_conn}=$thr;

	$self->{_cwindow}->SetDefaultStyle(Wx::TextAttr->new(wxBLACK));
	init_msg_text($self);
	$self->{_cwindow}->SetDefaultStyle(Wx::TextAttr->new(wxBLUE));
	$self->{_cwindow_color}=1;
	$self->{has_focus}=1;
	$topsizer->Fit($self);
	$topsizer->SetSizeHints($self);
	$self->Centre(wxBOTH);
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
		@dataout=(t::t("Incorrect login or password."));
		my $threvent = new Wx::PlThreadEvent( -1, $LOGOUT_EVENT, $result );
		Wx::PostEvent( $handler, $threvent );
		return 1;
	}
	while(1) {
		my $command;
		my $signal=0;
		my $ret=undef;
		# here we parse commands that were built by the interface
		foreach $command (@dataout) {
			if ($command eq "quit") { $mrim->disconnect; return 1; }
			elsif ($command =~ m/^s([0-9]+)\s(.*)/) {
			 	my $contact=$clistkeys[$1-1];
			 	my $cfullname=$clistitems[$1-1];
				my $msg=$2;
				if ($contact ne 'x') {
					$ret=$mrim->send_message($contact,$msg);
					$contact=~s/\@(mail.ru|inbox.ru|list.ru|bk.ru)//;
					push @datain, my_local_time()." > $contact > ".$msg."\n";
					push @datatypein, 'TO';
					$signal=1;
				} else {
					push @datain, my_local_time()." xx ($cfullname) xx ".$msg."\n";
					push @datatypein, 'TO';
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
				$ret=$mrim->authorize_user($1);
			}
			elsif ($command =~ m/^search\s(.*)/) {
				my ($email,$sex,$country,$online)=split(/\|/,$1);
				$ret=$mrim->search_user($email,$sex,$country,$online);
			}
		}
		@dataout=();
		$ret=$mrim->ping() if (!defined($ret));
		# here we process messages we received from server, if any
		if ($ret->is_message()) {
			my $from=$ret->get_from();
			$from=~s/\@(mail.ru|inbox.ru|list.ru|bk.ru)//;
			if ($from ne 'OFFLINE') {
				push @datain, my_local_time()." ".$from." > ".$ret->get_message()."\n";
				push @datatypein, 'FROM';
			} else {
				push @datain, t::t('OFFLINE MESSAGE')."\n".$ret->get_message()."\n";
				push @datatypein, 'FROMOFF';
			}	
			$signal=1;
		} elsif ($ret->is_server_msg()) {
			if ($ret->get_subtype() == $ret->{TYPE_SERVER_ANKETA}) {
				my $ainfo=$ret->get_message();
				my $anketa='<table border="0" cellpadding="4" cellspacing="0">';
				my $umail='';
				foreach my $info (split(/\n/,$ainfo)) {
					if (($info=~m/^User/i)||($info=~m/^Nickname/i)||($info=~m/^Firstname/i)||($info=~m/^LastName/i)
										||($info=~m/^Sex/i)||($info=~m/^Birthday/i)||($info=~m/^Location/i)) {
						my $infoline=$info."\n";
						$infoline=~s/\t+: /\<\/b\>\<\/td\>\<td\>/;
						$infoline=~s/\n//;
						$infoline='<tr><td><b>'.$infoline;
						if ($info=~m/^User/i) {
							$umail=$info ;
							$umail=~s/^User\t+: (.*)$/$1/;
							$infoline.="</td><td rowspan=\"7\"><img src=\"".$mrim->get_contact_avatar_url($umail)."\">";
						}
						$anketa.=$infoline."</td></tr>\n";
					}
					if ($info=~m/\-\-\-\-\-\-\-\-\-\-/) {
						$anketa.="<tr><td colspan=\"3\"><hr></td></tr>\n";
					}
				}
				$anketa.='</table>';
				push @datain, $anketa;
				push @datatypein, 'ANKETA';
			} elsif ($ret->get_subtype() == $ret->{TYPE_SERVER_NOTIFY}) {
				my $msg=$ret->get_message();
				$msg=~s/ \| /\n/g;
				my ($tmaillabel,$umaillabel)=(t::t('Total Mails'),t::t('Unread Mails'));
				$msg=~s/MESSAGES.TOTAL/$tmaillabel/;
				$msg=~s/MESSAGES.UNREAD/$umaillabel/;
				$msg=~s/NEW_MAIL/$umaillabel/;
				push @datain, "$msg\n";
				push @datatypein, 'SERVER';
			} elsif ($ret->get_subtype() == $ret->{TYPE_SERVER_AUTH_REQUEST}) {
				my $msg=$ret->get_from()."|".$ret->get_message();
				push @datain, "$msg\n";
				push @datatypein, 'AUTHREQ';
			} else {
				print $ret->get_message()."\n";
			}
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
					$clistkeys[$icl]='x';
				}
			}
			$clistupd = 1;
			$signal=1;
		} elsif ($ret->is_logout_from_server()) {
			# send logout event to main app
			@dataout=(t::t("Logged out from server.\nMaybe you connected from another location.\nReconnect?"));
			my $threvent = new Wx::PlThreadEvent( -1, $LOGOUT_EVENT, $result );
			Wx::PostEvent( $handler, $threvent );
			return 1;
		}
		# here is to send event to the main app to update itself
		if ($signal==1) {
			my $threvent = new Wx::PlThreadEvent( -1, $DONE_EVENT, $result );
			Wx::PostEvent( $handler, $threvent );
		}
	}
}

# below are event handlers

# text has been entered in the input test field
sub OnTextEnter {
	my $frame=shift;
	my $input=$frame->{_entertext}->GetValue();
	$input=Encode::encode("cp1251",$input);
	my @indexes=$frame->{_clist}->GetSelections();
	if (scalar(@indexes)>0) {
		$frame->{_entertext}->Clear();
		push @dataout, 's'.$onlineids[$indexes[0]].' '.$input;
		$frame->{_status}->SetLabel(t::t("Sending..."));
	} else {
		show_error($frame,t::t("No contact selected !"));
	}
}

# an event has been launched by the MRIM connection thread
sub OnThreadEvent {
	my( $frame, $event ) = @_;
	for (my $i=0; $i<scalar(@datain); $i++) {
		my $data=$datain[$i];		
		Encode::from_to($data,"cp1251","utf8");
		if ($datatypein[$i] eq 'ANKETA') {
			show_info($frame,$data);
		} elsif ($datatypein[$i] eq 'SERVER') {
			show_notify($frame,"<pre><font size='+1'><b>$data</b></font></pre>",0);
		} elsif ($datatypein[$i] eq 'FROMOFF') {
			show_notify($frame,"<pre><font size='-1'>$data</font></pre>",1);
		} elsif ($datatypein[$i] eq 'AUTHREQ') {
			$data=~m/^(.*)\|(.*)/;
			show_notify($frame,"<b>$1 :</b><br>$2",2,$1);
		} else {
			if ($datatypein[$i] eq 'TO') {
				$frame->{_cwindow}->SetDefaultStyle(Wx::TextAttr->new(wxRED)) if ($frame->{_cwindow_color} == 1);
				$frame->{_cwindow_color} = 2;
				append_msg_text($frame,$data);
			} else {
				$frame->{_cwindow}->SetDefaultStyle(Wx::TextAttr->new(wxBLUE)) if ($frame->{_cwindow_color} == 2);
				$frame->{_cwindow_color} = 1;
				append_msg_text($frame,$data);
				$frame->RequestUserAttention() if (($NOTIFY==1)||(($Wx::VERSION>0.80)&&(!$frame->IsActive())));
			}
		}
	}
	@datain=();
	@datatypein=();
	if (selected_contact($frame) ne '') {
		$frame->{_status}->SetLabel(t::t("Send to").": ".selected_contact($frame));
	} else {
		$frame->{_status}->SetLabel("");
	}
	# update contact list
	if ($clistupd==1) {
		my $selecteditem='';
		my $selectedindex=-1;
		my $j=0;
		# memorize selected contact, if any
		my @indexes=$frame->{_clist}->GetSelections();
		if (scalar(@indexes)>0) {
			$selecteditem=$onlinemails[$indexes[0]];
		}
		# flush and update contact list
		@onlinekeys=();
		@onlinemails=();
		@onlineids=();
		for (my $i=0; $i<scalar(@clistkeys); $i++) {
			my $clitem=$clistkeys[$i];
			my $cllabel=$clistitems[$i];
			if ($DISPLAY_NICK==0) {
				$cllabel=$clitem;
			} else {
				Encode::from_to($cllabel,"cp1251","utf8");
			}
			$cllabel=~s/^(.*)\@[a-z\.]+$/$1/i;
			if ($clitem ne 'x') {
				push @onlinekeys, "".$cllabel." ";
				push @onlinemails, "".$clitem;
				push @onlineids, "".($i+1);
				$selectedindex=$j if ($selecteditem eq $clitem);
				$j++;
			}
		}
		$frame->{_clist}->Set(\@onlinekeys);
		# restore selected contact, if any
		if ($selectedindex>-1) {	
			$frame->{_clist}->SetSelection($selectedindex);
			$frame->{_status}->SetLabel(t::t("Send to").": ".$selecteditem);
		}
		$frame->{_topsizer}->Fit($frame);
		$frame->{_topsizer}->SetSizeHints($frame);
		$clistupd=0;
	}
}

# a logout event has been launched by the MRIM connection thread
sub OnLogoutEvent {
	my( $frame, $event ) = @_;
	my $rec=show_error($frame,"".$dataout[0],1);
	if ($rec==wxID_YES) {
		# now restart the thread that connects to MRIM
		my $thr = threads->create(\&mrim_conn,$frame);
		$frame->{_conn}=$thr;
	} else {
		exit;
	}
}

# an item has been selected in the contact list
sub OnListBoxClicked {
	my $frame=shift;
	my @indexes=$frame->{_clist}->GetSelections();
	if (scalar(@indexes)>0) {
		$frame->{_status}->SetLabel(t::t("Send to").": ".$onlinemails[$indexes[0]]);
	}
	$frame->{_entertext}->SetFocus();
}

# a close event has been sent by the interface
sub OnQuit {
	my $frame=shift;
	$frame->{_status}->SetLabel(t::t("Disconnecting...."));
	push @dataout,"quit";
	$frame->{_conn}->join() if (defined($frame->{_conn}));;
	exit;
}

# an info request event has been sent by the interface
sub OnInfo {
	my $frame=shift;
	my @indexes=$frame->{_clist}->GetSelections();
	if (scalar(@indexes)>0) {
		push @dataout, "i".$onlineids[$indexes[0]];
	} else {
		show_error($frame,t::t("No contact selected !"));
	}	
}

# an "add user" event has been sent by the interface
sub OnAddUser {
	my $frame=shift;
	my $inputDialog = new MRIMInputDialog(t::t('Enter email of the user to add to contact list:'),'');
	$inputDialog->ShowModal();
	my $input=$inputDialog->getValue();
	if ($input =~ m/\@/) {
		push @dataout,"add ".$input;
	}
}

# a "remove user" event has been sent by the interface
sub OnDelUser {
	my $frame=shift;
	my $inputDialog = new MRIMInputDialog(t::t('Enter email of the user to remove from contact list:'),selected_contact($frame));
	$inputDialog->ShowModal();
	my $input=$inputDialog->getValue();
	if ($input =~ m/\@/) {
		push @dataout,"del ".$input;
	} 
}

# an "authorize user" event has been sent by the interface
sub OnAuthUser {
	my $frame=shift;
	my $inputDialog = new MRIMInputDialog(t::t('Enter email of the user to authorize:'),selected_contact($frame));
	$inputDialog->ShowModal();
	my $input=$inputDialog->getValue();
	if ($input =~ m/\@/) {
		push @dataout,"auth ".$input;
	} 
}

# open search window...
sub OnSearchUser {
	my $frame=shift;
	my $searchDialog = new MRIMSearchDialog();
	$searchDialog->ShowModal();
	if ($searchDialog->getCancelled()==0) {
		my $str="search ".$searchDialog->getEmail().'|'.$searchDialog->getSex().'|'.$searchDialog->getCountry().'|'.$searchDialog->getOnline();
		push @dataout,$str;
	}
}

# about info...
sub OnAbout {
	my $frame=shift;
	show_info($frame,"<pre>PerlMRIM v$VERSION\n"
	."Copyright 2007-2008 Alexandre Aufrere &lt;aau\@cpan.org&gt;\n"
	."Protocol (c) Mail.Ru http://agent.mail.ru\n"
	."Running on wxPerl $Wx::VERSION</pre>");
}

# check for updates !
sub OnCheckUpdate {
	my $frame=shift;
	use LWP::UserAgent;
	my $ua = new LWP::UserAgent();
	$ua->agent("PerlMRIM/$VERSION");
	my $req = HTTP::Request->new(GET => 'http://www.nikosoft.net/mrim/version.php?myversion='.$VERSION.'&mylang='.$TLANG);
	my $res = $ua->request($req);
	if ($res->is_success) {
		show_info($frame,$res->content);
	}
}


# below are utility methods

sub selected_contact {
	my $frame=shift;
	my @indexes=$frame->{_clist}->GetSelections();
	if (scalar(@indexes)>0) {
		return ''.$onlinemails[$indexes[0]];
	}
	return '';
}

sub init_msg_text {
	my ($frame)=@_;
	open (HST,"".$ENV{HOME}."/.perlmrim.hst");
	my @hist=<HST>;
	close (HST);
	my $beginning=scalar(@hist)-$LAST_HISTORY_LINES;
	$beginning=0 if ($beginning<0);
	open (HST,">".$ENV{HOME}."/.perlmrim.hst");
	for (my $i=$beginning;$i<scalar(@hist);$i++) {
		$frame->{_cwindow}->AppendText($hist[$i]);
		print HST $hist[$i];
	}
	close (HST);
}

sub append_msg_text {
	my ($frame,$msg)=@_;
	$frame->{_cwindow}->AppendText($msg);
	open (HST,">>".$ENV{HOME}."/.perlmrim.hst");
	print HST $msg;
	close (HST);
}

sub show_error {
	my ($frame,$msg,$yesno)=@_;
	my $flag=wxICON_ERROR;
	$flag=$flag|wxYES_NO|wxYES_DEFAULT if ($yesno==1);
	my $msgbox=Wx::MessageDialog->new($frame,$msg,"Error",$flag);
	$msgbox->Centre(wxBOTH);
	return $msgbox->ShowModal();
}

sub show_info {
	my ($frame,$msg)=@_;
	my $msgbox=new MRIMInfoDialog($msg);
	$msgbox->Show();
}

sub show_notify {
	my ($frame,$msg,$ntype,$nvalue)=@_;
	my $msgbox=new MRIMNotifyDialog($msg,$ntype,$nvalue);
	$msgbox->Show();
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

$TLANG=get_lang();

# Locale charset is set as UTF-8.
setlocale(LC_ALL,$TLANG.'.UTF-8');
$ENV{LANG}=$TLANG.'.UTF-8';
$TLANG=~s/^([a-z][a-z]).*$/$1/;
my $app = MRIMApp->new;
$app->MainLoop;

exit;

# utility function for i18n
sub get_lang {
	my $lang='en_US';
	if ($^O eq 'linux') {
		$lang=$ENV{LANG};
	} elsif ($^O eq 'darwin') {
		$lang=`/usr/bin/defaults read -g AppleLocale`;
	} 
	$lang=~s/\n//;
	return $lang;
}

package t;

# translate !
sub t {
	my ($str)=@_;
	if ($TRNS[0] eq '0') {
		open (TRN,'trans.ini');
		@TRNS=<TRN>;
		close TRN;
	}
	my $strn='';
	foreach my $ltrn (@TRNS) {
		if ($ltrn=~m/^\[([a-z][a-z])\]$/) {
			$strn=$1;
		}
		if ($strn eq $TLANG) {
			$ltrn=~s/\n//;
			my ($orig,$trans)=split(/\=/,$ltrn);
			return $trans if ($orig eq $str);
		}
	}
	return $str;
}


1;
