package CGI::Application::Plus ;
$VERSION = 1.0 ;

; use strict
; use Carp

######### NEW ############

; use Class::constr
      ( { init       => [ qw| cgiapp_init setup | ]
        , no_strict  => 1
        }
      )

######### GROUPS ############

; use Object::groups
      ( { name       => [ qw | param
                               header_props
                             |
                        ]
        , no_strict  => 1
        }
      , { name       => 'run_modes'
        , no_strict  => 1
        , pre_process => sub
                         { if ( ref $_[1] eq 'ARRAY' )
                            { $_[1] = { map { $_=>$_ } @{$_[1]} }
                            }
                         }
        }
      )

######### PROPERTIES ############

; use Object::props
      ( { name       => '__STEP'
        , default    => 0
        , allowed    => qr/::run$/
        }
      , { name       => 'mode_param'
        , default    => 'rm'
        }
      , { name       => 'query'
        , default    => sub { $_[0]->cgiapp_get_query }
        , no_strict  => 1  # doesn't croak if fetched too late
        , validation => sub
                         { croak qq(Too late to set the query)
                           if $_[0]->__STEP > 0       # just before run
                         ; 1
                         }
        }
      , { name       => 'runmode'
        , default    => 'start'
        , validation => sub
                         { croak qq(Too late to set the run mode)
                           if ( $_[0]->__STEP >= 2     # after prerun
                              && (caller(2))[3] !~ /::_run_runmode$/
                              )
                          ; 1
                          }
        }
      , { name       => 'tmpl_path'
        , default    => './tm'
        , no_strict  => 1    # doesn't croak if ./tm is not a valid path
        , validation => sub { -d or croak qq(Not a valid path) }
        }
      , { name       => 'RM_prefix'
        , default    => 'RM_'
        }
      , { name       => 'header_type'
        , default    => 'header'
        , validation => sub{ /^(header|redirect|none)$/ }
        }
      , { name       => 'page'
        }
      )

######### PARAM AUTOLOAD ############

; our $AUTOLOAD

; sub AUTOLOAD :lvalue                 # Param AUTOLOADING
   { (my $n = $AUTOLOAD) =~ s/.*://
   ; return if $n eq 'DESTROY'
   ; @_ == 2
     ? ( $_[0]{param}{$n} = $_[1] )
     :   $_[0]{param}{$n}
   }
           
######### OVERRIDE METHODS ############

; BEGIN
   { no strict 'refs'
   ; foreach my $n qw| cgiapp_init
                       cgiapp_prerun
                       cgiapp_postrun
                       teardown
                     |
      { *$n = sub {}
      }

   }

; sub cgiapp_get_query
   { require CGI
   ; CGI->new
   }
   
; sub setup
   { $_[0]->run_modes( start => \&dump_html )
   }
         
######### METHODS ############

; sub run
   { my ($s, $RM) = @_
   ; $s->__STEP = 1
   ; unless ( defined $RM && length $RM )        # no RM from script
      { $RM = ref $s->mode_param eq 'CODE'
              ? $s->mode_param->($s)             # RM from code ref
              : $s->query->param($s->mode_param) # RM from query
      }
   ; unless ( defined $RM && length $RM )        # no RM yet
      { $RM = $s->runmode                        # RM from default
      }
     else
      { $s->runmode = $RM                        # shitch RM
      }
     
   ; $s->__STEP = 2
   ; $s->cgiapp_prerun( $RM )          # passed just for full compatibility
   ; $s->__STEP = 3
   ; $s->_run_runmode( $RM )
                 if $RM eq $s->runmode # if unchanged by prerun
   ; $s->__STEP = 4
   ; $s->page = \ ( my $p = $s->page )
                unless ref $s->page
   ; $s->cgiapp_postrun( $s->page )    # passed just for compatibility
   ; my $output = $s->_send()
   ; $s->teardown()
   ; $output
   }

; *switch_to = sub{shift()->_run_runmode(@_)}

; sub _run_runmode         # __STEP must be 2 or 3 to run this
   { my ($s, $RM, @args) = @_
   ; $s->__STEP < 2 && croak qq(Too early to call this method)
   ; $s->__STEP > 3 && croak qq(Too late to call this method)
   ; defined $RM && length $RM || croak qq(No run mode passed)
   ; $s->runmode = $RM    # switch RM allowed just from here
   ; my $rm = $s->run_modes
   ; my $runmethod = $$rm{$RM}
                   || $s->can($s->RM_prefix.$RM) && $s->RM_prefix.$RM
                   || ($$rm{AUTOLOAD} && ++ my $al && $$rm{AUTOLOAD})
   ; $^W && $al && carp qq(No run-method found for run mode "${\$s->runmode}" )
                      . qq(using run mode "AUTOLOAD")
   ; my $page
   ; if ( $runmethod )
      { unshift @args, $RM if $al
      ; $page = $s->can($runmethod)
                ? $s->$runmethod( @args )
                : eval{ $s->$runmethod( @args ) }
      ; $@ && croak qq(Error executing run mode "${\$s->runmode}": $@)
      }
   ; unless ( defined $s->page )
      { $runmethod
        || croak qq(No run-method found for run mode "${\$s->runmode}")
      ; $s->page = $page
      }
   }
   
; sub _send
   { my $s = shift
   ; $s->start_capture if $ENV{CGI_APP_RETURN_ONLY}     # testing only
   ; print $s->query->${\$s->header_type}( %{$s->header_props} )
           unless $s->header_type eq 'none'
   ; my $p = $s->page
   ; if ( ref $p eq 'CODE' )
      { eval { $p->($s) }
      ; $@ && croak qq(Error executing the code referenced )
                  . qq(by run mode "${\$s->runmode}": $@)
      }
     elsif ( ref $p eq 'SCALAR' )
      { print $$p
      }
     elsif ( not ref $p )
      { print $p
      }
   ; $s->stop_capture if $ENV{CGI_APP_RETURN_ONLY}   # testing only
   }
  
######### OLD CGI APP ############

; BEGIN
   { # useless but aliased for compatibility (support OO overriding)
   ; *QUERY               = sub{shift()->query(@_)}
   ; *PARAMS              = sub{shift()->param(@_)}
   ; *TMPL_PATH           = sub{shift()->tmpl_path(@_)}
   ; *start_mode
   = *get_current_runmode = sub{shift()->runmode(@_)}
   ; *prerun_mode         = sub{shift()->_run_runmode(@_)}
   ; *header_add          = sub{shift()->header_props(@_)}
   }

######### JUST FOR TEST ############

; BEGIN  # block needed just to allow testing
   { no strict 'refs'
   ; foreach my $n qw| dump dump_html load_tmpl |
      { *$n = sub
               { require CGI::Application::Plus::Util
               ; goto &{"CGI::Application::Plus::Util::$n"}
               }
      }
   }

######### CAPTURE ############

; my $output
; local *H

; sub start_capture  # starts to capture output
   { $output = ''
   ; *H = '*'.select()
   ; tie *H , 'CGI::Application::Plus::Capt' , \ $output
   }

; sub stop_capture   # returns captured output
   { untie *H
   ; $output
   }

; package CGI::Application::Plus::Capt

; sub TIEHANDLE
   { bless \@_, shift
   }
 
; sub PRINT
   { my $s = shift
   ; ${$$s[0]} .= join $,||'', map{$_||''} @_
   }
   
; 1

__END__

=head1

=head1 NAME

CGI::Application::Plus - CGI::Application rewriting with several pluses

=head1 VERSION 1.0

Included in CGI-Application-Plus 1.0 distribution. The distribution includes:

=over

=item * CGI::Application::Plus

CGI::Application rewriting with several pluses

=item * CGI::Application::Magic

Template based framework for CGI applications

=item * CGI::Application::CheckRM

Checks run modes using Data::FormValidator

=back

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1
    OOTools      >= 1.52

=item CPAN

    perl -MCPAN -e 'install CGI::Application::Plus'

If you want to install also all the prerequisites to use C<CGI::Application::Magic>), all in one easy step:

    perl -MCPAN -e 'install Bundle::CGI::Application::Magic'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SYNOPSIS

In WebAppl.pm

    # instead of "use base 'CGI::Application';"
    use base 'CGI::Application::Plus' ;
    
    # all the new possibilities are described below

=head1 DESCRIPTION

This module is a complete new stand alone reimplementation of C<CGI::Application> module (i.e. it is not a subclass). It adds several new features to your CGI::Application implementation, maintaining intact the old ones, so if some new feature is not useful to you, just use the old way that still works.

Since all the 'old-features' are excellently documented in L<CGI::Application>, right now this documentation focuses only on the new features that this module implements exclusively. (please see also L<"CONTRIBUTION">)

Since this documentation is not yet stand alone, you should integrate both documentation and please, be sure to understand that module before to switch to this one.

B<IMPORTANT NOTE>: If you write any script that rely on this module, you better send me an e-mail so I will inform you in advance about eventual planned changes, new releases, and other relevant issues that could speed-up your work. (see also L<"CONTRIBUTION">)

=head2 Why yet another CGI::Application?

I greatly apreciate the general philosophy of the cgiapp system but I wasn't satisfied with several aspect of its implementation, so I started to write a sub class. Very soon I realized that I would had to overriding at least the new, run and param methods. Then, after overriding all that, it would have been stupid to have to depend and to be limited from another module just for the few subs that remain original, so... I wrote this module that is a completely new and different approach to the same general metaphor. Just look at the source to see what I mean.

If you are thinking that this module is like reinventing the wheel... well... just think about how slow, unsure and unconfortable would be your car if it would use the first original hand-made-wooden wheels of several centuries ago :-).

=head1 CGI::Application::Plus Vs CGI::Application

=head2 Exclusive Features and Improvements

This is the list of all the improvements and new features that you gain by using C<CGI::Application::Plus> instead of C<CGI::Application>.

=head3 Properties

Most of the old C<CGI::Application> methods fit well into the category of 'object property', and so they are implemented in the C<CGI::Application::Plus> module by using OOTools pragmas.

B<Note>: A property is simply an accessor to an object value, used by methods. All the C<CGI::Application::Plus> properties are lvalue accessors, that means that you can create a reference to them, assign to them and apply a regex to them, (some have a default value, some have validation entry rules, etc.)

    $s->runmode = 'myStart'     # 'runmode' is a property accessor
    delete $s->param->{myParam} # 'param' is a property group accessor

=head3 new ()

The new() method accept more options: see L<new()|"new ( [ properties ] )">.

=head3 run ()

The run() method accept more options: see L<run()|"new ( [ runmode ] )">.

=head3 param handling

The C<param()> accessor is a property group acccessor, that means that you can set, add, retrieve, delete, check for existance with only one method. You can use it as a parameter to the new() method as well. (see L<param()|"param ( [ parameters ] )">)

    # pass a parameter to the new object
    $webapp = WebApp->new(param => {myPar => 'myPAR'})
    
    # same thing using the AUTOLOAD method
    $webapp = WebApp->new(myPar => 'myPAR')
    
    $s->param(myPar1=>'myPARAM1',
              myPar2=>'myPARAM2') ;
    
    $s->param(\%other_param) ;
              
    $P = $s->param ;
    while ( my ($p, $v) = each %$P )
    { do_something_useful }
    
    # check if exists a parameter
    exists $s->param->{myPar} ;
    
    # delete a parameter
    delete $s->param->{myPar} ;

=head3 header handling

The header_props() is a property group acccessor, so you can set, add, retrieve, delete headers exactly like what you can do with the param() accessor. (No needs of any C<add_header()> method)

=head3 page property

Under old C<CGI::Application> implementation, a run method is espected to return the content of the page (or a reference to it) to send to the client.

C<CGI::Application::Plus> can work that way as well, but it adds the new C<page> property that can considerably improve the flexibility of your application. (see L<"page"> property)

B<Note>: Just completely ignore the C<page> property to exactly reproduce the same old C<CGI::Application> behaviour. Anyway, this possibility is here just for compatibility, and it is deprecated: please always use the C<page> property.

=head3 run method prefix

I hate to write twice the same information, because it is silly, annoying and error prone, so... unless you need to address a run mode to some particular method you can completely avoid the C<run_modes()> method and keep safe your application by using a prefixed name for your run mode methods:

    # this run method does not need to be declared with run_modes()
    # and will be executed automatically by run mode 'myRunmode'
    
    sub RM_myRunmode
    {
      do_something_useful
    }

B<Note>: You can set the C<RM_prefix> property to change the default prefix.

=head3 run mode switching

You have an useful method to switch to a run mode (see L<switch_to()|"switch_to ( runmode [, arguments] )">)

=head3 overriding for power users

All the internal data have an accessor that you can override to have it changed across the whole class, and in the code there are no dirty statements like C<< $self->{SOME_INTERNAL_STUFF} = 'something' >> that bypass the accessor.

=head3 Efficiency

Under normal environment this module should load a little faster and use less memory than C<CGI::Application> thanks to the far shorter code and the use of OOTools pragmas, that implements efficient closure accessors at compile time. (see L<Object::props>, L<Object::groups>, L<Class::constr>)

=head3 Super Classes

If you write a super class and need some more properties for your class, you can use the OOTools pragmas for free (memory). They are already loaded by this module and allows you to give a more consistent interface to your users, creating very efficient accessors at compile time with just a couple of lines. Take a look at the source of the modules in this distribution to understand what I mean.

=head1 CGI::Application compatibility

An old C<CGI::Application> implementation should run unchanged under C<CGI::Application::Plus> as well, taking the advantages of all the pluses of this module (this module pass all the test of CGI::Application 3.1, but if you found some incompatibilities, please tell me, and I will fix it).

B<Note>: The compatibility could be compromised if your application used some dirty hack that bypass accessors (i.e. some statements that interacts with the internal hash structure of the C<CGI::Application> class, something like C<< $self->{__PARAMS} >>, because C<CGI::Application::Plus> implements a more consistent but different internal structure).

=head2 param()

This module implements on purpose a little but useful difference that should not break the code of anybody, that correct IMHO a weird and useless behaviour of C<CGI::Application::param()>:

    # CGI::Application param() in scalar context
    $par = $s->param() ;                  # $par == number of params || undef
    $par = $s->param(myPar =>'myPARAM') ; # $par eq 'myPARAM'
    $par = $s->param(myPar1=>'myPARAM1',  # $par is undef
                     myPar2=>'myPARAM2') ;
    $par = $s->param('myPar') ;           # $par eq 'myPARAM'
    
    # CGI::Application::Plus param() in scalar context
    $par = $s->param() ;                  # ref $par eq 'HASH'
    $par = $s->param(myPar =>'myPARAM') ; # ref $par eq 'HASH'
    $par = $s->param(myPar1=>'myPARAM1',  # ref $par eq 'HASH'
                     myPar2=>'myPARAM2') ;
    $par = $s->param('myPar') ;           # $par eq 'myPARAM'

As you see, in scalar context (no difference in list context) the C<param()> metod returns the reference to the underlying hash containing the parameters. This allows you to interact directly with the whole hash, or checking and deleting single parameters very easily:

    $P = $s->param ;
    while ( my ($p, $v) = each %$P )
    { do_something_useful }
    
    # check if exists a parameter
    exists $s->param->{myPar} ;
    
    # delete a parameter
    delete $s->param->{myPar} ;

=head2 cgiapp_postrun()

More than a difference this is a new possible situation that this method should be ready to handle. It will receive the reference to the output in $_[1] as usual, but, just in case you set the page property to a CODE reference (see L<"page"> property), it will receive that reference. If your cgiapp_postrun() method need to collect the output it can capture the output using a couple of methods implemented for that purpose

    sub cgiapp_postrun
    {
      my ($s, $ref) = @_ ;         # $ref always the same as $s->page
      if (ref $ref eq 'CODE')
      {
        $s->start_capture() ;
        $ref->($s) ;               # executes $ref CoDE (print)
        $$ref = $s->stop_capture ; # now $ref is the ref to the content
      }
      # do something with $ref as usual
    }

=head2 Useless but supported aliases

To maintain compatibility with the old C<CGI::Application> implementation, this module provides all the old - and now useless - aliases.

=over

=item QUERY

Used to pass a query object with the C<new()> method. It's still working but deprecated use C<query> property instead.

    $webapp = WebApp->new(query=>CGI->new)

=item TMPL_PATH

Used to pass a template path with the C<new()> method. It's still working but deprecated use C<tmpl_path> property instead

    $webapp = WebApp->new(tmpl_path=>'/mypath')

=item PARAMS

Used to pass a reference to an hash (containing some parameters) with the C<new()> method. It's still working but deprecated. You can use several alternatives with C<param()> property group acccessor or accessing parameters directly. (see L<param()> property group acccessor)

    $webapp = WebApp->new(param => { myParam => 'myPARAM'} )
    # same thing
    $po = myAppl->new(myParam => 'myPARAM')

=item start_mode ()

Used to set the start run mode. It's still working but deprecated use C<runmode> property instead.

    $s->runmode = 'mystart'

=item get_current_runmode ()

Used to get the current run mode. It's still working but deprecated use C<runmode> property instead.

    $s->runmode  # always returns the current run mode

=item prerun_mode ()

Used to set the prerun mode. It's still working but deprecated use C<switch_to()> method instead.

    $s->switch_to = 'myRunmode'

=item header_add ()

Used to adds some headers after the C<header_props()> method is called. It's still working but deprecated. The C<header_props()> property group accessor do it already, so use it instead.

=back

=head1 METHODS

Please integrates the documentation in this section with L<CGI::Application>

=head2 new ( [ properties ] )

The new() method accepts and sets any known object property, storing any unknow property as a new parameter. You can pass to the new() method all the property you usually set with the setup() or cgiapp_init() metods that can however set (override) them as usual. This just adds a new flexible possibility to configure your application not from inside the application module, but from the cgi script that uses it:

    # not all useful here, but possible
    $webapp = WebApp->new(runmode    => 'mySpecialRunMode',
                          mode_param => 'mm' ,
                          runmodes   => [ qw|one two| ] ,
                          myParam    => 'myPARAM' ,  # sets param 'myParam'
                          ... more here...    )

=head2 run ( [ runmode ] )

You can directly pass a run mode to the run() method, so forceing the application to run that run mode (e.g. useful when testing a particular run mode):

    $webapp->run('mySpecialRunmode');

B<Note for power users only>: The run() method is splitted into 3 internal methods ( run(), _run_runmode(), _send() ) so you can eventually selectively override them in a more flexible way.

=head2 switch_to ( runmode [, arguments] )

This method allows you to switch to a run mode, e.g. useful when validating run modes.

    sub RM_myRunmode
    {
      my $s = shift;
      some_condition || return $s->switch_to('myOtherRunmode', @optional_arg)
      ...
    }

You should use this method inside the C<cgiapp_prerun()> method too. (old way was to set the prerun_mode())

=head2 start_capture()

Use this method to start to capture the current selected filehandler (usually STDOUT). All the printed output will be captured and will not go in the selected filehandler until you use the Cstop_capture()> method.

B<Note>: this method is internally called when C<$ENV{CGI_APP_RETURN_ONLY}> is set to a true value.

=head2 stop_capture()

This method will return the captured output and will stop the capture.

B<Note>: this method is internally called when C<$ENV{CGI_APP_RETURN_ONLY}> is set to a true value.

=head2 AUTOLOAD

This method (not to be confused with the 'AUTOLOAD' run mode) implements an handy parameter accessor. You can store or retrieve a parameter as it where an object property:

    # instead of do this
    $s->param(myPar => 'some init value')
    
    # you can do this
    $s->myPar = 'some init value' ;
    
    # same thing with the new() method
    $webapp = WebApp->new(myPar => 'some init value')
    
    # and to retrieve
    $p = $s->myPar

If you don't like this feature, just override the AUTOLOAD method. If your application implements its own AUTOLOAD sub and you want to keep this possibility just fall back on the SUPER class method when needed.

=head1 OVERRIDE METHODS

Please refer to L<CGI::Application>

=head1 PROPERTY GROUP ACCESSORS

With all the property group accessors you can set, add, retrieve, delete, check for existance with only one method. You can use them as a parameter to the new() method as well. See below for examples

=head2 param ( [ parameters ] )

This accessor handles the parameters of your application

    # pass a parameter to the new object
    $webapp = WebApp->new(param => {myPar => 'myPAR'})
    
    $s->param(myPar1=>'myPARAM1',
              myPar2=>'myPARAM2') ;
    
    $s->param(\%other_param) ;
    
    $P = $s->param ;
    while ( my ($p, $v) = each %$P )
    { do_something_useful }
    
    # check if exists a parameter
    exists $s->param->{myPar} ;
    
    # delete a parameter
    delete $s->param->{myPar} ;

=head2 header_props( [ headers ] )

This accessor works for headers exactly like param() works for parameters. No need of any add_header() method.

=head2 run_modes( [ runmodes ] )

This accessor manages the declared run_modes. It works as all the other accessors but adds the possibility to receive reference to an ARRAY as argument, that will be expanded as this

    $webapp->run_modes([ 'mode1', 'mode2', 'mode3' ]);
    
    #same as this
    $webapp->run_modes(
        'mode1' => 'mode1',
        'mode2' => 'mode2',
        'mode3' => 'mode3'
    );

Please, consider that in order to reduce redundancy in your code, you can use safely the C<RM_prefix> property, to avoid to declare run modes and run methods (see L<"run method prefix">)

=head1 PROPERTY ACCESSORS

All the property accessors are lvalue method that means that you can create a reference to them, assign to them and apply a regex to them, (some have a default value, some have validation entry rules, etc.) Old assignation will work as well

   $s->property = 'value'
   
   #same thing
   $s->property('value')

You can use them as a parameter to the new() method as well.

   $webapp = WebApp->new(some_property => 'some_value')

=head2 runmode

This property allows you to access and set the runmode. The default for this property is 'start'.

Set the C<runmode> to redefine the default run mode. The default run mode will be used whenever the value of the CGI form parameter specified by the C<mode_param> property is not defined.

    # in setup
    $s->runmode = 'myStart' ;
    
    $current_runmode = $s->runmode

=head2 query

This property allows you to access and set the query object. The default for this property is a CGI query object, but you can override this default if you redefine the C<cgiapp_get_query()> method.

If, for some reason, you want to use your own CGI query object, you can pass this property to the new() method, or you can also directly set it at same point in the process before the run() method (or in the C<cgiapp_prerun()> method).

    $s->query = CGI->new({myOwnQuery => 'something'}) ;

=head2 mode_param

This property allows you to access and set the name of the query parameter used to retrieve the runmode. The default for this property is 'rm'.

=head2 tmpl_path

This property allows you to access and set the directory where the templates are stored. The default for this property is './tm'.

=head2 RM_prefix

This property allows you to access and set the prefix string used to find a not declared runmode. The default for this property is 'RM_'. (see also L<"run method prefix">)

=head2 header_type

This property allows you to access and set the type of header your application will send. The default for this property is 'header'. You can chose 'header', 'redirect', 'none'.

=head2 page

This property allows you to access and set the content of the page (or a reference to it) to send to the client. A run method should set the C<page> property to some page content, to a reference to it or to a CODE reference that will print the output on its own. in this case the refereced code will be called after the printing of the headers.

    sub RM_myRunMode
    {
      ...do_something_useful...
      $s->page  = 'something'
      $s->page .= 'something more'
    }
    
    sub RM_myOtherRunMode
    {
      ...do_something_useful...
      $s->page  = \&print_the_content
    }

The main advantage to set this property to a CODE reference (among others) is that you can avoid to charge the memory with the whole (and sometime huge) output and print it while it is produced.

This feature is fully utilized in L<CGI::Application::Magic|CGI::Application::Magic>, but you can also use it with your own subroutines (see also L<"page property">)

=head2 __STEP

Internal property used to control exceptions.

=head1 TESTING

=head2 $ENV{CGI_APP_RETURN_ONLY}

When set to a true value it cause the capture of the output being printed, so it will not be sent to STDOUT, besides the run() method will return the captured output, so allowing you to eventually test your sub classes.

   $ENV{CGI_APP_RETURN_ONLY} = 1
   
   $captured_output = $webapp->run();
   if ( $captured_output =~ /something to test/ )
   {
      print 'ÍT WORKS!'
   }

=head1 TO DO

=over

=item *

Improve exception handling

=item *

Make this documentation stand alone

=back

=head1 SUPPORT and FEEDBACK

I would like to have just a line of feedback from everybody who tries or actually uses this module. PLEASE, write me any comment, suggestion or request. ;-)

More information at http://perl.4pro.net/?CGI::Application::Plus.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to anyone that contributes to the creation of the C<CGI::Application> metaphor: the merit of that great idea still belong to them.

=head1 CONTRIBUTION

I always answer to each and all the message i receive from users, but I have almost no time to find, install and organize a mailing list software that could improve a lot the support to people that use my modules. Besides I have too little time to write more detailed documentation, more examples and tests. Your contribution would be precious, so if you can and want to help, just contact me. Thank you in advance.
