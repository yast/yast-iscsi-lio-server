#! /usr/bin/perl -w
#
# functions for IscsiServer module written in Perl
#

package IscsiServerFunctions;
use strict;
use YaST::YCP qw(:LOGGING);
use Data::Dumper;
use YaPI;
use Switch;

YaST::YCP::Import ("SCR");


our %TYPEINFO;

# map of auth and target values
my %config = ();

# map for ini-agent
my %config_file = ();

# for remember add and deleted targets
my %changes = ();

my @new_target = ();

# read data given from ini-agent and put values into %config map
BEGIN { $TYPEINFO{parseConfig} = ["function", ["map", "string", "any"], ["map", "string", "any"] ]; }
sub parseConfig {
    my $self = shift;
    %config_file = %{+shift};
    my $values =  $config_file{'value'};

    my $scope="auth";
    foreach  my $row ( @$values ){

     if ($$row{'name'} eq 'Target'){
      $scope = $$row{'value'};
      $config{$scope} =  [ {'KEY' => 'Target', 'VALUE' => $scope } ];
	} else {

	if ( $$row{'name'}=~'iSNS' ) {$scope = 'iSNS';}
	 else {
		$scope='auth' if ($scope eq 'iSNS');	
		}

	    if (!ref($config{$scope})) {
	     $config{$scope} = [ {'KEY' => $$row{'name'}, 'VALUE' => $$row{'value'} } ];
	    } else {
	    push(@{$config{$scope}}, ({'KEY'=>$$row{'name'}, 'VALUE'=>$$row{'value'}}));
	   }
	}
    };
    return \%config;
}

# remove given target by name
# remove item with given key from %config and return result 
BEGIN { $TYPEINFO{removeTarget} = ["function", ["map", "string", "any"], "string" ]; }
sub removeTarget {
    my $self = shift;
    my $key = shift;
    %config = %{$self->removeKeyFromMap(\%config, $key)};
    return \%config;
}

# accessor for %config
BEGIN { $TYPEINFO{getConfig} = ["function", ["map", "string", "any"] ]; }
sub getConfig {
    my $self = shift;
    return \%config;
}

# internal function :
# return given map without given key
sub removeKeyFromMap {
 my $self = shift;
 my %tmp_map = %{+shift};
 my $key = shift;

 delete $tmp_map{$key} if defined $tmp_map{$key};
 return \%tmp_map;
}

# return targets (ommit 'auth' from %config)
BEGIN { $TYPEINFO{getTargets} = ["function", ["map", "string", "any"] ] ; }
sub getTargets {
 my $self = shift;

 return $self->removeKeyFromMap($self->removeKeyFromMap(\%config, 'auth'), 'iSNS');
}

# set discovery authentication
BEGIN { $TYPEINFO{setAuth} = ["function", "void", ["list", "string"], "string" ]; }
sub setAuth {
    my $self = shift;
    my @incoming = @{+shift};
    my $outgoing = shift;
    my @tmp_auth = ();

	foreach my $row (@incoming){
	 push(@tmp_auth, {'KEY'=>'IncomingUser', 'VALUE'=>$row});
	}

 push(@tmp_auth, {'KEY'=>'OutgoingUser', 'VALUE'=>$outgoing}) if ($outgoing =~/[\w]+/);
 $config{'auth'}=\@tmp_auth;
}

# set iSNS data
BEGIN { $TYPEINFO{setiSNS} = ["function", "void", "string", "string" ]; }
sub setiSNS {
    my $self = shift;
    my $ip = shift;
    my $ac = shift;
    my @isns = ();


 push(@isns, {'KEY'=>'iSNSServer', 'VALUE'=>$ip}) if ($ip ne '');
 push(@isns, {'KEY'=>'iSNSAccessControl', 'VALUE'=>$ac}) if ($ac ne '');
 $config{'iSNS'}=\@isns;
}
# set authentication for given target
BEGIN { $TYPEINFO{setTargetAuth} = ["function", "void", "string", ["list", "string"], "string" ]; }
sub setTargetAuth {
    my $self = shift;
    my $target = shift;
    my @incoming = @{+shift};
    my $outgoing = shift;
    my $tmp_auth = \@new_target;

  my @before_values=();
  foreach my $row (@{$tmp_auth}){
   push(@before_values, $row) if (($$row{'KEY'} ne 'IncomingUser')&&($$row{'KEY'} ne 'OutgoingUser'));
  }
  @{$tmp_auth}=@before_values;

 foreach my $row (@incoming){
  push(@$tmp_auth, {'KEY'=>'IncomingUser', 'VALUE'=>$row});
 }
 push(@$tmp_auth, {'KEY'=>'OutgoingUser', 'VALUE'=>$outgoing}) if ($outgoing =~/[\w]+/);

# @new_target = @$tmp_auth;
}

# set LUN's for target
BEGIN { $TYPEINFO{setLUN} = ["function", "void", "string", ["list", [ "map", "string", "any" ] ] ] ; }
sub setLUN {
 my $self = shift;
 my $target = shift;
 my $lun = shift;

 if (ref($config{$target})){
  my @tmp_list = @{$config{$target}};
  my @list=();
  foreach my $row (@tmp_list){
   push(@list, $row) if ($row->{'KEY'} ne 'Lun');
  }
  @tmp_list=@list;
  @new_target = @tmp_list;
  push(@new_target, @{$lun});
 }  
}


# create new target
BEGIN { $TYPEINFO{addNewTarget} = ["function", "void", "string", ["list", [ "map", "string", "any" ] ]] ; }
sub addNewTarget {
 my $self = shift;
 my $target = shift;
 my $lun = shift;

my @tmp_list = ( {'KEY'=>'Target', 'VALUE'=>$target} );

 if (ref($config{$target})){
  my @tmp_list = @{$config{$target}};
  my @list=();
  foreach my $row (@tmp_list){
   push(@list, $row) if (($$row{'KEY'} ne 'Target')&&($$row{'KEY'} ne 'Lun'));
  }
  @tmp_list=@list;
  @new_target = @tmp_list;
 push(@new_target, ( {'KEY'=>'Target', 'VALUE'=>$target} ));
 } else { @new_target = ( {'KEY'=>'Target', 'VALUE'=>$target} ); }
push(@new_target, @{$lun});
}


BEGIN { $TYPEINFO{saveNewTarget} = ["function", "void", "string" ] ; }
sub saveNewTarget {
 my $self = shift;
 my $target = shift;

 @{$config{$target}} = @new_target;
 @new_target=();
}


BEGIN { $TYPEINFO{editTarget} = ["function", ["list", "any"], "string" ] ; }
sub editTarget {
 my $self = shift;
 my $target = shift;

 @new_target = @{$config{$target}};
 return $config{$target};
}


# check whether target/lun already exists
BEGIN { $TYPEINFO{ifExists} = ["function", "boolean", "string", "string" ] ; }
sub ifExists {
 my $self = shift;
 my $key = shift;
 my $val = shift;
 
 my $ret = 0;

 foreach my $target (keys %config) {
 if ($target ne 'auth'){
  foreach my $tmp_hash (@{$config{$target}}){
   if (($$tmp_hash{'KEY'} eq $key)&&($$tmp_hash{'VALUE'} eq $val)) { 
	$ret = 1;
    }
   }
  }
 }
 return $ret; 
}


# internal function
# create map from given map in format needed by ini-agent
sub createMap {
 my ($old_map, $comment) = @_;

 $comment='' if (ref($comment) eq 'ARRAY');
 my %tmp_map = (
		"name"=>$old_map->{"KEY"},
           "value"=>$old_map->{"VALUE"},
           "kind"=>"value",
           "type"=>1,
           "comment"=> $comment 
		);
 return \%tmp_map;
}

# internal function
# copy each row from $config{$target} to $old_map but in format needed by ini-agent
sub addTo {
 my ($old_map, $target) = @_;
 my @tmp_list = ();

 foreach my $row (@{$config{$target}}){
  push(@tmp_list, createMap( $row, [] ));
 }
 $old_map->{$target}=\@tmp_list;
 return $old_map;
}

# parse %config and write it to %config_file for ini-agent
BEGIN { $TYPEINFO{writeConfig} = ["function", ["map", "string", "any"] ]; }
sub writeConfig {
    my $self = shift;
    my $values =  $config_file{'value'};
    my %new_config = ();

    # read old configuration and write it to %new_config
    my $scope="auth";
    foreach  my $row ( @$values ){
     if ($$row{'name'} eq 'Target'){
      $scope = $$row{'value'};
      $new_config{$scope} =  [ $row ];
     } else {

	    if (!ref($new_config{$scope})) {
	     $new_config{$scope} = [ $row ];
	    } else {
		    push(@{$new_config{$scope}}, ($row));
	 	   }
	   }
    };
    # deleted items add to $changes{'del'}
    foreach my $key (keys %new_config){
     if (! defined $config{$key}){
      delete($new_config{$key});
#      push(@{$changes{'del'}}, $key);
     }
    }

    foreach my $key (keys %config){
     if (! defined $new_config{$key}){
      # add new items
      addTo(\%new_config, $key);
#      push(@{$changes{'add'}}, $key) if ($key ne 'auth');
     } else {
	 # for modifying store comments
	 my %comments = ();
	 foreach my $row (@{$new_config{$key}}){
	  $comments{$row->{'name'}} = $row->{'comment'} if ($row->{'comment'} ne '');
	  $comments{$row->{'name'}}='' if (not defined $comments{$row->{'name'}});
	 }
	 my @new = ();
	 foreach my $row (@{$config{$key}}){
	  my $k = $row->{'KEY'};
	  $comments{$k}='' if not defined $comments{$k};
	 # and put it to new map with old comments
	 push(@new, createMap($row, $comments{$k}));
	 $comments{$k}='';
	 }
	 $new_config{$key} = \@new;
	}
    }
    # write 'iSNS' and 'auth' into %new_config
    if (defined $new_config{'iSNS'}){
      $config_file{'value'} = $new_config{'iSNS'};
      delete ($new_config{'iSNS'});
    }
    if (defined $new_config{'auth'}){
      @{$config_file{'value'}} = (@{$config_file{'value'}}, @{$new_config{'auth'}}) ;
      delete ($new_config{'auth'});
    }
    #write all targets into %new_config
    foreach my $key (reverse(keys %new_config )){
     if (not ref($new_config{$key})){
      push(@{$config_file{'value'}}, $new_config{$key}) ;
     } else {
	     push(@{$config_file{'value'}}, @{$new_config{$key}}) ;
	    }
    }
    return \%config_file;
}

# get now connected targets
BEGIN { $TYPEINFO{getConnected} = ["function", ["list", "string"] ]; }
sub getConnected {
 open(PROC, "< /proc/net/iet/session");
 my $target="";
 my @connected = ();
 foreach my $row (<PROC>){
  $target=$1 if ( $row =~ /tid:[\d]+ name:([\S]+)/);
  my $find = 0;

   foreach my $conn (@connected){
    $find = 1 if ( $conn =~ $target);
   }
  push(@connected, $target) if (( $row =~ /sid:[\d]+/)&&(not $find));
 }
 close(PROC);
return \@connected;
}

# accessor for %changes
BEGIN { $TYPEINFO{getChanges} = ["function", ["map", "string", "any"] ]; }
sub getChanges {
 return \%changes;
}


# set modified for %changes
BEGIN { $TYPEINFO{setModifChanges} = ["function", "integer", "string" ]; }
sub setModifChanges {
 my $self = shift;
 my $target = shift;
 my $ret = 0;

 foreach my $section (("del", "add")){
  foreach my $row (@{$changes{$section}}){
   $ret=1 if ($row eq $target);
  }}

  if ($ret==0){
   push(@{$changes{"del"}}, $target);
   push(@{$changes{"add"}}, $target);
  }

 return \$ret;
}


# set deleted for %changes
BEGIN { $TYPEINFO{setDelChanges} = ["function", "integer", "string" ]; }
sub setDelChanges {
 my $self = shift;
 my $target = shift;
 my $ret = 0;

 foreach my $section (("del", "add")){
  my @list=();
  foreach my $row (@{$changes{$section}}){
   push(@list, $row) if ($row ne $target);
  }
  $changes{$section}=\@list;
 }
  push(@{$changes{"del"}}, $target);

 return \$ret;
}

BEGIN { $TYPEINFO{SaveIntoFile} = ["function", "boolean", "string" ]; }
sub SaveIntoFile {
 my $self = shift;
 my $filename = shift;
 my $file="";
 my $delimiter = "---------------------\n";

 my $auth = $self->getConfig()->{"auth"};
 if (defined $auth && scalar(@{$auth})>0){
  $file = "Discovery authentication:\n" . $delimiter;
  foreach my $row (@{$auth}){
    $file = $file . $row->{'KEY'} . ": " . $row->{'VALUE'} . "\n";
  }
  $file = $file . "\n";
 }

# my $isns = $self->getConfig()->{"iSNS"};
# if (defined $isns && $isns>0){
#  foreach my $row (@{$isns}){
#    y2internal("isns ", Dumper($row));
#  }
# }

 my %targets = %{$self->getTargets()};
 if (scalar(keys %targets)>0){
  $file = $file . "Targets\n" . $delimiter . "\n";
 }
 foreach my $target (keys %targets){
  my $target_name = "";
  my @auths	  = ();
  my @luns 	  = ();
   foreach my $row (@{$targets{$target}}){
    switch ($row->{'KEY'}) {
      case ('Target') {
	$target_name = $row->{'VALUE'};
      }
      case ('Lun') {
	push(@luns, $row->{'VALUE'});
      }
      case ('IncomingUser' || 'OutgoingUser') {
	push(@auths, $row->{'KEY'} . ": " . $row->{'VALUE'})
      }
    }
  }
  $file = $file . $target_name . "\n";
  $file = $file . "Luns: " . join(', ', @luns) . "\n" if (scalar(@luns) > 0);
  $file = $file . join("\n", @auths) if (scalar(@auths) > 0);
  $file = $file . "\n";
 }

 y2milestone("Save report : \n", $file);

  my $result = SCR -> Write (".target.string", $filename, $file);
 y2milestone("Save result: ", $result);
 return $result;
}


1;
# EOF
