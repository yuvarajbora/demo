#!/usr/bin/perl

BEGIN {
  if (-e 't/test_dir') { # if we are running "t/rule_tests.t", kluge around ...
    chdir 't';
  }

  if (-e 'test_dir') {            # running from test directory, not ..
    unshift(@INC, '../blib/lib');
    unshift(@INC, '../lib');
  }
}

use lib '.'; use lib 't';
use SATest; sa_t_init("urilocalbl");

use constant HAS_GEOIP => eval { require Geo::IP; };

use Test::More;

plan skip_all => "Geo::IP not installed" unless HAS_GEOIP;
plan tests => 9;

# ---------------------------------------------------------------------------

tstpre ("
loadplugin Mail::SpamAssassin::Plugin::URILocalBL
");

%patterns = (
  q{ X_URIBL_USA } => 'USA',
  q{ X_URIBL_FINEG } => 'except Finland',
  q{ X_URIBL_NA } => 'north America',
  q{ X_URIBL_EUNEG } => 'except Europe',
  q{ X_URIBL_ISP } => 'Level 3 Communications',
  q{ X_URIBL_CIDR1 } => 'our TestIP1',
  q{ X_URIBL_CIDR2 } => 'our TestIP2',
  q{ X_URIBL_CIDR3 } => 'our TestIP3',
);

tstlocalrules ("
  geodb_module GeoIP
  geoip_search_path data/geodb

  uri_block_cc X_URIBL_USA us
  describe X_URIBL_USA uri located in USA
  
  uri_block_cc X_URIBL_FINEG !fi
  describe X_URIBL_FINEG uri located anywhere except Finland

  uri_block_cont X_URIBL_NA na
  describe X_URIBL_NA uri located in north America

  uri_block_cont X_URIBL_EUNEG !eu !af
  describe X_URIBL_EUNEG uri located anywhere except Europe/Africa

  uri_block_isp X_URIBL_ISP \"Level 3 Communications\" Google \"Foo Bar\" \"x y z\"
  describe X_URIBL_ISP isp is Level 3 Communications

  uri_block_cidr X_URIBL_CIDR1 8.0.0.0-255.255.255.0
  describe X_URIBL_CIDR1 uri is our TestIP1

  uri_block_cidr X_URIBL_CIDR2 8.8.8.8
  describe X_URIBL_CIDR2 uri is our TestIP2

  uri_block_cidr X_URIBL_CIDR3 8.8.8.0/24
  describe X_URIBL_CIDR3 uri is our TestIP3
");

ok sarun ("-L -t < data/spam/relayUS.eml", \&patterns_run_cb);
ok_all_patterns();
