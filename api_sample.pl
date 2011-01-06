#!/usr/bin/perl

# This is a sample application written in perl which uses system calls
# to wget for accessing the Trusonic COA API. 
# 
# Ideally, an application would store the API key until it is expired
# and only refresh it when it's either expired or non existant. 
#
# Also, should change from using wget to LWP

use strict;
use Digest::MD5 qw(md5 md5_hex);
use XML::Simple;
use Data::Dumper;
my $xml = new XML::Simple;

my $debug = 0;

my $client_uid = "";
my $client_pwd = "";
my $auth_realm = "";
my $api_host = "";
my $api_path = "services";
my $api_key = $ARGV[0] || get_auth_key();

# use wget to access the API
my $wgetter = "wget -q -O -";

print " api_key  = $api_key\n" if $debug;

# Now that we have an api_key, we can start getting data 
my $get_zone_list = "http://$api_host/$api_path?api_key=$api_key&cmd=date_range_list";
my $zone_list = `$wgetter '$get_zone_list'`;

print "$zone_list\n\n";


sub get_auth_key {
   my $wgetter = "wget -q -O -";
   
   # Retrieve the nonce used for digest authentication
   my $login_url = "http://$api_host/$api_path?cmd=login";
   my $get_nonce = `$wgetter '$login_url'`;
   my $nonce_xml = $xml->XMLin($get_nonce);
   my $auth_nonce = $nonce_xml->{error}->{nonce};
   
   my @digest;
   my $md5 = Digest::MD5->new;

   my $md5_pwd = Digest::MD5->new;
   $md5_pwd->add( $client_pwd );
   my $enc_pwd = $md5_pwd->hexdigest;
   $md5_pwd->reset;
   
   $md5->add( join( ":", $client_uid, $auth_realm, $enc_pwd ) );
   push( @digest, $md5->hexdigest );
   $md5->reset;
   
   print " md5      = $digest[0]\n" if $debug;
   
   # # Append the nonce to the digest and hash again
   # # to construct the response
   
   push( @digest, $auth_nonce );
   $md5->add( join( ":", @digest ) );
   my $client_response = $md5->hexdigest;
   $md5->reset;
   
   print " username = $client_uid\n" if $debug;
   print " realm    = $auth_realm\n" if $debug;
   print " nonce    = $auth_nonce\n" if $debug;
   print " response = $client_response\n" if $debug;
   
   # # Send the response to the server to get the api_key
   my $api_key_url = "http://$api_host/$api_path?cmd=login&user=$client_uid&nonce=$auth_nonce&realm=$auth_realm&response=$client_response";
   my $get_api_key = `$wgetter '$api_key_url'`;
   my $login_xml = $xml->XMLin($get_api_key);
   my $api_key = $login_xml->{login}->{api_key};
   
   print " url      = $api_key_url\n" if $debug;

return($api_key);
}
