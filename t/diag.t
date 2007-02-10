#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
require Test::Simple::Catch;
my($out, $err) = Test::Simple::Catch::caught();
local $ENV{HARNESS_ACTIVE} = 0;

use Test::More tests => 2;
use Test::JavaScript;

js_ok("diag('Hello World');", "Warn hello");
print $out->read;

my $warn = $err->read;
chomp $warn;

js_is("\"$warn\"","# Hello World", "warned $warn");
print $out->read;
