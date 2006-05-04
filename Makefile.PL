#!/usr/bin/perl
    
package main;

use strict;
use warnings (FATAL => 'all');
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'Test-JavaScript',
    VERSION      => '0.01',
    AUTHOR	 => 'Kevin Jones',
    ABSTRACT	 => 'JavaScript unit testing',
    PREREQ_PM    => {
	JavaScript::SpiderMonkey => 0,
	Test::Simple => 0,
    },
    clean        => { FILES => '*.ppd *.tar.gz' },
);

