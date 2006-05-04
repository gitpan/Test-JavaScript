package Test::JavaScript;

=head1 NAME

Test::JavaScript - JavaScript Testing Module

=head1 SYNOPSIS

    use Test::JavaScript qw(no_plan);

    use_ok("/path/to/MyFile.js");

    ok("var obj = new MyFile", "Create a MyFile object");

    ok("obj.someFunction = function () { return 'ok' }");

    is("obj.someFunction()", "ok");

=head1 DESCRIPTION

Test::JavaScript provides a method of unit testing javascript code from within
perl. This module uses the JavaScript::SpiderMonkey package to evaluate
JavaScript using the SpiderMonkey JavaScript engine.

=cut

use strict 'vars';
use warnings;

use Exporter;
use Carp qw(croak);

use Test::Builder;
my $Test = Test::Builder->new;

use JavaScript::SpiderMonkey;
my $js = JavaScript::SpiderMonkey->new();
$js->init();
$js->eval("var test_js = new Object;");

our @ISA    = qw(Exporter);
our @EXPORT = qw(ok use_ok is isnt);

$js->function_set("ok", sub { $Test->ok(@_) });
$js->function_set("is", sub { $Test->is_eq(@_) });
$js->function_set("isnt", sub { $Test->isnt_eq(@_) });
$js->function_set("warn", sub { warn @_ });

return 1;

END { $js->destroy };

sub no_ending { $Test->no_ending(@_) }

sub import {
    my $self = shift;
    my $caller = caller;

    for my $f (@EXPORT) {
	*{$caller.'::'.$f} = \&$f;
    }

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub try_eval {
    my ($code, $name) = @_;
    my $rc = $js->eval($code);
    unless ($rc) {
	my $ok = $Test->ok( !$@, $name );
        $Test->diag(<<DIAGNOSTIC);
    $@
DIAGNOSTIC
	$@ = '';
    }
}

sub escape_args {
    my $name = pop @_;
    my @args = @_;
    $args[0] = $name and $name = '' unless @args;
    s/'/\\'/g foreach @args;
    (my $escaped = $name) =~ s/'/\\'/g;
    return (@args,$escaped,$name);
}

=item B<use_ok>

  use_ok($filename)

This reads a file and evals it in JavaScript

For example:

    use_ok( "/path/to/some/file.js" );

=cut

sub use_ok ($;@) {
    my $filename = shift || croak "filename required";
    croak "$filename doesn't exist" unless $filename;

    open my $fh, $filename or die "Couldn't read $filename: $!";
    my @lines = <$fh>;
    close $fh or die "Couldn't read $filename: $!";

    my $rc = $js->eval(join("\n", @lines));
    my $ok = $Test->ok( !$@, "use $filename;" );

    unless( $rc ) {
        $Test->diag(<<DIAGNOSTIC);
    Tried to use '$filename'.
    $@
DIAGNOSTIC
    }
}

=item B<is>

=item B<isnt>

  is  ( $this, $that, $test_name );
  isnt( $this, $that, $test_name );

This compares two values in JavaScript land. They can be literal strings
passed from perl or variables defined earlier.

For example:

    ok("var i = 3");					// ok
    is("i", 3, "i is 3");				// ok
    is("3", 3, "3 is 3");				// ok
    is("3", 2, "3 is 2");				// not ok

    ok("function three () { return 3 }");		// ok
    is("three()", 3);					// ok
    is("three()", 4);					// not ok

    isnt("3", 4, "3 is not 4");				// ok

=cut

sub is {
    my ($test,$actual,$ename,$name) = escape_args(@_);
    my $code = <<EOT;
is( $test, '$actual', '$ename'.replace(/\\'/,"'"));
EOT
    try_eval($code, $name);
}

sub isnt {
    my ($test,$actual,$ename,$name) = escape_args(@_);
    my $code = <<EOT;
isnt( $test, '$actual', '$ename'.replace(/\\'/,"'"));
EOT
    try_eval($code, $name);
}

=item B<ok>

  ok("var monkey = 3", $test_name);

The expression passed as the first parameter is evaluated as either true or
false. The test fails if the expression explicitly returns false, or if a
syntax error occurs in JavaScript land

For example:

    ok("var i = 3");					// ok
    ok("true", "true is true");				// ok
    ok("1 == 2", "1 is equal to 2");			// not ok
    ok("false", "false is false");			// not ok
    ok("var array = ['one','two',non_existing_var];")	// not ok

=cut

sub ok {
    my ($test,$ename,$name) = escape_args(@_);
    my $lines = join"\n", map { "code.push('$_');" } split("\n", $test);
    my $code = <<EOT;
var code = new Array;
$lines
var result = eval(code.join("\\n")) ? true : false;
ok( result, '$ename'.replace(/\\'/,"'"));
EOT

    try_eval($code, $name);
}

