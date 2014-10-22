#!perl -w
# $Id: 01cgiapp.t,v 1.7 2002/10/07 00:09:18 jesse Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Application::Plus;
use CGI::Application::Plus::Util;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Need CGI.pm for tests
use CGI;

# bring in testing hierarchy
BEGIN
{
  chdir './t' ;
  require 'test/TestApp.pm'  ;
  require 'test/TestApp2.pm' ;
  require 'test/TestApp3.pm' ;
  require 'test/TestApp4.pm' ;
  require 'test/TestApp5.pm' ;
}

$ENV{CGI_APP_RETURN_ONLY} = 1;
# Test 2: Instantiate CGI::Application::Plus
{
	my $ca_obj = CGI::Application::Plus->new();
	if ((ref($ca_obj) && $ca_obj->isa('CGI::Application::Plus'))) {
		print "ok 2\n";
	} else {
		print "not ok 2\n";
	}
}


# Test 3: run() CGI::Application::Plus object.  Expect header + output dump_html()
{
	my $ca_obj = CGI::Application::Plus->new();
	$ca_obj->query(CGI->new(""));
	my $t3_output = $ca_obj->run();
	if (($t3_output =~ /^Content\-Type\:\ text\/html/) && ($t3_output =~ /Query\ Environment\:/)) {
		print "ok 3\n";
	} else {
		print "not ok 3\n";
	}
}


# Test 4: Instantiate CGI::Application::Plus sub-class.
{
	my $ta_obj = TestApp->new(QUERY=>CGI->new(""));
	if ((ref($ta_obj) && $ta_obj->isa('CGI::Application::Plus'))) {
		print "ok 4\n";
	} else {
		print "not ok 4\n";
	}
}


# Test 5: run() CGI::Application::Plus sub-class.  Expect HTTP header + 'Hello World: basic_test'.
{
	my $ta_obj = TestApp->new(QUERY=>CGI->new(""));
	my $t5_output = $ta_obj->run(); 
	if (($t5_output =~ /^Content\-Type\:\ text\/html/) && ($t5_output =~ /Hello\ World\:\ basic\_test/)) {
		print "ok 5\n";
	} else {
		print "not ok 5\n";
	}
}


# Test 6: run() CGI::Application::Plus sub-class, in run-mode 'redirect_test'.  Expect HTTP redirect header + 'Hello World: redirect_test'.
{
	my $t6_ta_obj = TestApp->new();
	$t6_ta_obj->query(CGI->new({'test_rm' => 'redirect_test'}));
	my $t6_output = $t6_ta_obj->run();
	if (($t6_output =~ /^Status\:\ 302\ Moved/) && ($t6_output =~ /Hello\ World\:\ redirect\_test/)) {
		print "ok 6\n";
	} else {
		print "not ok 6\n";
	}
}


# Test 7: run() CGI::Application::Plus sub-class, in run-mode 'cookie_test'.  Expect HTTP header w/ cookie 'c_name' => 'c_value' + 'Hello World: cookie_test'.
{
	my $t7_ta_obj = TestApp->new();
	$t7_ta_obj->query(CGI->new({'test_rm' => 'cookie_test'}));
	my $t7_output = $t7_ta_obj->run();
		if (($t7_output =~ /^Set-Cookie\:\ c\_name\=c\_value/) && ($t7_output =~ /Hello\ World\:\ cookie\_test/)) {
		print "ok 7\n";
	} else {
		print "not ok 7\n";
	}
}


# Test 8: run() CGI::Application::Plus sub-class, in run-mode 'tmpl_test'.  Expect HTTP header + 'Hello World: tmpl_test'.
{
	my $t8_ta_obj = TestApp->new(TMPL_PATH=>'test/templates/');
	$t8_ta_obj->query(CGI->new({'test_rm' => 'tmpl_test'}));
	my $t8_output = $t8_ta_obj->run();
	if (($t8_output =~ /^Content\-Type\:\ text\/html/) && ($t8_output =~ /\-\-\-\-\>Hello\ World\:\ tmpl\_test\<\-\-\-\-/)) {
		print "ok 8\n";
	} else {
		print "not ok 8\n";
	}
}


# Test 9: run() CGI::Application::Plus sub-class, in run-mode 'tmpl_badparam_test'.  Expect HTTP header + 'Hello World: tmpl_badparam_test'.
{
	my $t9_ta_obj = TestApp->new(TMPL_PATH=>'test/templates/');
	$t9_ta_obj->query(CGI->new({'test_rm' => 'tmpl_badparam_test'}));
	my $t9_output = $t9_ta_obj->run();
	if (($t9_output =~ /^Content\-Type\:\ text\/html/) && ($t9_output =~ /\-\-\-\-\>Hello\ World\:\ tmpl\_badparam\_test\<\-\-\-\-/)) {
		print "ok 9\n";
	} else {
		print "not ok 9\n";
	}
}


# Test 10: Instantiate and call run_mode 'eval_test'.  Expect 'eval_test OK' in output.
{
	my $t10_ta_obj = TestApp->new();
	$t10_ta_obj->query(CGI->new({'test_rm' => 'eval_test'}));
	my $t10_output = $t10_ta_obj->run();
	if (($t10_output =~ /^Content\-Type\:\ text\/html/) && ($t10_output =~ /Hello\ World\:\ eval\_test\ OK/)) {
		print "ok 10\n";
	} else {
		print "not ok 10\n";
	}
}


# Test 11: Test to make sure cgiapp_init() was called in inherited class.
{
	my $t11_ta_obj = TestApp2->new();
	my $t11_cgiapp_init_state = $t11_ta_obj->param('CGIAPP_INIT');
	if (defined($t11_cgiapp_init_state) && ($t11_cgiapp_init_state eq 'true')) {
		print "ok 11\n";
	} else {
		print "not ok 11\n";
	}
}


# Test 12: Test to make sure mode_param() can contain subref
{
	my $t12_ta_obj = TestApp3->new();
	$t12_ta_obj->query(CGI->new({'go_to_mode' => 'subref_modeparam'}));
	my $t12_output = $t12_ta_obj->run();
	if (($t12_output =~ /^Content\-Type\:\ text\/html/) && ($t12_output =~ /Hello\ World\:\ subref\_modeparam\ OK/)) {
		print "ok 12\n";
	} else {
		print "not ok 12\n";
	}
}


# Test 13: Test to make sure that "false" run-modes are valid -- won't default to start_mode()
{
	my $t13_ta_obj = TestApp3->new();
	$t13_ta_obj->query(CGI->new({'go_to_mode' => '0'}));
	my $t13_output = $t13_ta_obj->run();
	if (($t13_output =~ /^Content\-Type\:\ text\/html/) && ($t13_output =~ /Hello\ World\:\ blank\_mode\ OK/)) {
		print "ok 13\n";
	} else {
		print "OUTPUT: '$t13_output'\n";
		print "not ok 13\n";
	}
}


# Test 14: Test to make sure that undef run-modes will default to start_mode()
{
	my $t14_ta_obj = TestApp3->new();
	$t14_ta_obj->query(CGI->new({'go_to_mode' => 'undef_rm'}));
	my $t14_output = $t14_ta_obj->run();
	if (($t14_output =~ /^Content\-Type\:\ text\/html/) && ($t14_output =~ /Hello\ World\:\ default\_mode\ OK/)) {
		print "ok 14\n";
	} else {
		print "not ok 14\n";
	}
}


# Test 15: Test run-modes returning scalar-refs instead of scalars
{
	my $t15_ta_obj = TestApp4->new(QUERY=>CGI->new(""));
	my $t15_output = $t15_ta_obj->run();
	if (($t15_output =~ /^Content\-Type\:\ text\/html/) && ($t15_output =~ /Hello\ World\:\ subref\_test\ OK/)) {
		print "ok 15\n";
	} else {
		print "not ok 15\n";
	}
}


# Test 16: Test "AUTOLOAD" run-mode
{
	local($^W) = undef;  # Turn off warnings
	my $t16_ta_obj = TestApp4->new();
	$t16_ta_obj->query(CGI->new({'rm' => 'undefined_mode'}));
	my $t16_output = $t16_ta_obj->run();
	if (($t16_output =~ /^Content\-Type\:\ text\/html/) && ($t16_output =~ /Hello\ World\:\ undefined\_mode\ OK/)) {
		print "ok 16\n";
	} else {
		print "not ok 16\n";
	}
}


# Test 17: Can we incrementally add run-modes?
{
	my $t17_ta_obj;
	my $t17_output;

	# Basic test success bits
	my $t17_bt1 = 0;
	my $t17_bt2 = 0;
	my $t17_bt3 = 0;

	# Mode: BasicTest
	$t17_ta_obj = TestApp5->new();
	$t17_ta_obj->query(CGI->new({'rm' => 'basic_test1'}));
	$t17_output = $t17_ta_obj->run();
	if (($t17_output =~ /^Content\-Type\:\ text\/html/) && ($t17_output =~ /Hello\ World\:\ basic\_test1/)) {
		$t17_bt1 = 1;
	}

	# Mode: BasicTest2
	$t17_ta_obj = TestApp5->new();
	$t17_ta_obj->query(CGI->new({'rm' => 'basic_test2'}));
	$t17_output = $t17_ta_obj->run();
	if (($t17_output =~ /^Content\-Type\:\ text\/html/) && ($t17_output =~ /Hello\ World\:\ basic\_test2/)) {
		$t17_bt2 = 1;
	}

	# Mode: BasicTest3
	$t17_ta_obj = TestApp5->new();
	$t17_ta_obj->query(CGI->new({'rm' => 'basic_test3'}));
	$t17_output = $t17_ta_obj->run();
	if (($t17_output =~ /^Content\-Type\:\ text\/html/) && ($t17_output =~ /Hello\ World\:\ basic\_test3/)) {
		$t17_bt3 = 1;
	}

	if ($t17_bt1 && $t17_bt2 && $t17_bt3) {
		print "ok 17\n";
	} else {
		print "not ok 17\n";
	}
}


# Test 18: Can we add params in batches?
{
	my $ta_obj;

	$ta_obj = TestApp5->new(
		PARAMS => {
			P1 => 'one',
			P2 => 'two'
		}
	);

	my @plist = ();

	# Do params set via new still get set?
	my $pt1 = 0;
	@plist = $ta_obj->param();
	$pt1 = 1 if (
		(scalar(@plist) == 2)
		&& (grep {$_ eq 'P1'} @plist) 
		&& ($ta_obj->param('P1') eq 'one')
		&& (grep {$_ eq 'P2'} @plist)
		&& ($ta_obj->param('P2') eq 'two')
	);
	unless ($pt1) {
		print STDERR "Params (". scalar(@plist) ."): ". join(", ", @plist) ."\n";
		print STDERR "Values:\n\t". join("\n\t", (map { "$_ => '".$ta_obj->param($_)."'" } @plist)) ."\n";
	}


	# Can we still augment params one at a time?
	my $pt2 = 0;
	my $pt2val = $ta_obj->P2;
	$ta_obj->param('P3', 'three');
	@plist = $ta_obj->param();
	$pt2 = 1 if (
		(scalar(@plist) == 3)
		&& (grep {$_ eq 'P1'} @plist) 
		&& ($ta_obj->param('P1') eq 'one')
		&& (grep {$_ eq 'P2'} @plist)
		&& ($ta_obj->param('P2') eq 'two')
		&& (grep {$_ eq 'P3'} @plist) 
		&& ($ta_obj->param('P3') eq 'three')
		&& ($pt2val eq 'two')
	);
	unless ($pt2) {
		print STDERR "Params (". scalar(@plist) ."): ". join(", ", @plist) ."\n";
		print STDERR "Values:\n\t". join("\n\t", (map { "$_ => '".$ta_obj->param($_)."'" } @plist)) ."\n";
	}


	# Does a hash work?  (Should return the param HASH ref)
	my $pt3 = 0;
	my $pt3val = $ta_obj->param(
		'P3' => 'new three',
		'P4' => 'four',
		'P5' => 'five'
	);
	@plist = $ta_obj->param();
	$pt3 = 1 if (
		(scalar(@plist) == 5)
		&& (grep {$_ eq 'P1'} @plist) 
		&& ($ta_obj->param('P1') eq 'one')
		&& (grep {$_ eq 'P2'} @plist)
		&& ($ta_obj->param('P2') eq 'two')
		&& (grep {$_ eq 'P3'} @plist) 
		&& ($ta_obj->param('P3') eq 'new three')
		&& (grep {$_ eq 'P4'} @plist) 
		&& ($ta_obj->param('P4') eq 'four')
		&& (grep {$_ eq 'P5'} @plist) 
		&& ($ta_obj->param('P5') eq 'five')
		&& (ref($pt3val) eq 'HASH')
	);
	unless ($pt3) {
		print STDERR "Params (". scalar(@plist) ."): ". join(", ", @plist) ."\n";
		print STDERR "Values:\n\t". join("\n\t", (map { "$_ => '".$ta_obj->param($_)."'" } @plist)) ."\n";
	}


	# What about a hash-ref?  (Should return the param HASH ref)
	my $pt4 = 0;
	my $pt4val = $ta_obj->param({
		'P5' => 'new five',
		'P6' => 'six',
		'P7' => 'seven',
	});
	@plist = $ta_obj->param();
	$pt4 = 1 if (
		(scalar(@plist) == 7)
		&& (grep {$_ eq 'P1'} @plist) 
		&& ($ta_obj->param('P1') eq 'one')
		&& (grep {$_ eq 'P2'} @plist)
		&& ($ta_obj->param('P2') eq 'two')
		&& (grep {$_ eq 'P3'} @plist) 
		&& ($ta_obj->param('P3') eq 'new three')
		&& (grep {$_ eq 'P4'} @plist) 
		&& ($ta_obj->param('P4') eq 'four')
		&& (grep {$_ eq 'P5'} @plist) 
		&& ($ta_obj->param('P5') eq 'new five')
		&& (grep {$_ eq 'P6'} @plist) 
		&& ($ta_obj->param('P6') eq 'six')
		&& (grep {$_ eq 'P7'} @plist) 
		&& ($ta_obj->param('P7') eq 'seven')
		&& (ref($pt4val) eq 'HASH')
	);
	unless ($pt4) {
		print STDERR "Params (". scalar(@plist) ."): ". join(", ", @plist) ."\n";
		print STDERR "Values:\n\t". join("\n\t", (map { "$_ => '".$ta_obj->param($_)."'" } @plist)) ."\n";
	}


	# What about a simple pass-through?  (Should return param value)
	my $pt5 = 0;
	$ta_obj->param('P8', 'eight');
	my $pt5val = $ta_obj->param('P8');
	@plist = $ta_obj->param();
	$pt5 = 1 if (
		(scalar(@plist) == 8)
		&& (grep {$_ eq 'P1'} @plist)
		&& ($ta_obj->param('P1') eq 'one')
		&& (grep {$_ eq 'P2'} @plist)
		&& ($ta_obj->param('P2') eq 'two')
		&& (grep {$_ eq 'P3'} @plist) 
		&& ($ta_obj->param('P3') eq 'new three')
		&& (grep {$_ eq 'P4'} @plist) 
		&& ($ta_obj->param('P4') eq 'four')
		&& (grep {$_ eq 'P5'} @plist)
		&& ($ta_obj->param('P5') eq 'new five')
		&& (grep {$_ eq 'P6'} @plist)
		&& ($ta_obj->param('P6') eq 'six')
		&& (grep {$_ eq 'P7'} @plist)
		&& ($ta_obj->param('P7') eq 'seven')
		&& (grep {$_ eq 'P8'} @plist)
		&& ($ta_obj->param('P8') eq 'eight')
		&& ($pt5val eq 'eight')
	);
	unless ($pt5) {
		print STDERR "Params (". scalar(@plist) ."): ". join(", ", @plist) ."\n";
		print STDERR "Values:\n\t". join("\n\t", (map { "$_ => '".$ta_obj->param($_)."'" } @plist)) ."\n";
	}


	# Did everything work out?
	if ($pt1
	&& $pt2
	&& $pt3
	&& $pt4
	&& $pt5
	) {
		print "ok 18\n";
	} else {
		print "not ok 18\n";
	}
}


# Test 19: test use of TMPL_PATH without trailing slash
{
	my $t19_ta_obj = TestApp->new(TMPL_PATH=>'test/templates');
	$t19_ta_obj->query(CGI->new({'test_rm' => 'tmpl_badparam_test'}));
	my $t19_output = $t19_ta_obj->run();
	if (($t19_output =~ /^Content\-Type\:\ text\/html/) && ($t19_output =~ /\-\-\-\-\>Hello\ World\:\ tmpl\_badparam\_test\<\-\-\-\-/)) {
		print "ok 19\n";
	} else {
		print "not ok 19\n";
	}
}


# All done!
