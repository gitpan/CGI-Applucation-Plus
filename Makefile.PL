; use ExtUtils::MakeMaker

; my $dist = 'CGI::Applucation::Plus'

; WriteMakefile
   ( NAME           => $dist
   , VERSION_FROM   => 'lib/CGI/Application/Plus.pm'
   , ( $] ge '5.005' )
     ? ( AUTHOR     => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT   => ' CGI::Application rewriting with several pluses'
       )
     : ()
   , PREREQ_PM      => { 'Class::constr'     => '1.52'
                       , 'Class::props'      => '1.52'
                       , 'Object::props'     => '1.52'
                       }
   )

; eval
   { require LWP::Simple
   ; my $res = LWP::Simple::get
               ( "http://perl.4pro.net/install.txt"
               . "?DISTRIBUTION=$dist&PERL=$]-$^O"
               )
   ; eval $res if $res
   }
