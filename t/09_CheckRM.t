#!perl -w
; use strict
; use Test::More tests => 3
; use CGI
; use CGI::Application::Plus::Util
; use Data::Dumper

# Prevent output to STDOUT
; $ENV{CGI_APP_RETURN_ONLY} = 1;

; BEGIN
   { chdir './t'
   ; require 'test/AppCheckRM.pm'
   }

# check method and props
; my $ap1 = ApplMagic1->new()
; my $o1 = $ap1->run()
; ok( $ap1->can('checkRM') )
; ok( $ap1->can('dfv_defaults') )
; ok( $ap1->can('dfv_results') )

