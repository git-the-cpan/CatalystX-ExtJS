# 
# This file is part of CatalystX-ExtJS
# 
# This software is Copyright (c) 2010 by Moritz Onken.
# 
# This is free software, licensed under:
# 
#   The (three-clause) BSD License
# 
package CatalystX::Controller::ExtJS::REST;
BEGIN {
  $CatalystX::Controller::ExtJS::REST::VERSION = '1.101570';
}
# ABSTRACT: RESTful interface to dbic objects

use Moose;
extends qw(Catalyst::Controller::REST);
use MooseX::MethodAttributes;

use Config::Any;
use Scalar::Util ();
use Carp qw/ croak /;
use HTML::FormFu::ExtJS 0.076;
use Path::Class;
use HTML::Entities;
use Lingua::EN::Inflect;
use JSON::Any;

use Moose::Util::TypeConstraints;
subtype 'PathClassDir', as 'Path::Class::Dir';
coerce 'PathClassDir', from 'ArrayRef', via { Path::Class::Dir->new( @{$_[0]} ) };
coerce 'PathClassDir', from 'Str', via { Path::Class::Dir->new( $_[0] ) };
subtype 'PathClassFile', as 'Path::Class::File';
no Moose::Util::TypeConstraints;

__PACKAGE__->config(
    actions => {
        begin => {
            ActionClass => '+CatalystX::Action::ExtJS::Deserialize',
        },
        end => {
            ActionClass => 'Serialize',
        },
        list => {
            Chained        => '/', 
            NSListPathPart => undef, 
            Args           => undef, 
            Direct         => undef, 
            DirectArgs     => 1,
        },
        base => {
            Chained     => '/',
            NSPathPart  => undef,
            CaptureArgs => 1,
        },
        object => {
            Chained     => '/',
            NSPathPart  => undef,
            Args        => undef,
            ActionClass => '+CatalystX::Action::ExtJS::REST',
            Direct      => undef,
        },
        object_GET    => { Private => undef },
        object_PUT    => { Private => undef },
        object_POST   => { Private => undef },
        object_DELETE => { Private => undef },
    }
);

has '_extjs_config' => ( is => 'rw', isa => 'HashRef', builder => '_extjs_config_builder', lazy => 1 );

has 'form_base_path' => ( is => 'rw', lazy_build => 1, isa => 'PathClassDir', coerce => 1 );

has 'form_base_file' => ( is => 'rw', lazy_build => 1, isa => 'Path::Class::File' );

has 'list_base_path' => ( is => 'rw', lazy_build => 1, isa => 'PathClassDir', coerce => 1 );

has 'list_base_file' => ( is => 'rw', lazy_build => 1, isa => 'Path::Class::File' );

has 'list_options_file' => ( is => 'rw', lazy_build => 1, isa => 'PathClassFile|Undef' );

has 'form_config_cache' => ( is => 'rw', isa => 'HashRef', clearer => 'clear_form_config_cache', default => sub {{}});

has 'default_resultset' => ( is => 'rw', isa => 'Str', lazy_build => 1 );

# backwards compat
sub base_file { shift->form_base_file(@_) };
sub base_path { shift->form_base_path(@_) };


sub _extjs_config_builder {
    my $self = shift;
    my $c = $self->_application;
    my $default_rs_method = lc($self->default_resultset);
    $default_rs_method =~ s/::/_/g;
    
    my $defaults = {
        model_config => {
            schema => 'DBIC',
            resultset => $self->default_resultset
        },
        default_rs_method => 'extjs_rest_'.$default_rs_method,
        context_stash     => 'context',
        list_options_validation => {
            elements => [
                { name => 'start', constraints => ['Integer', { type => 'MinRange', min => 0}] },
                { name => 'dir', constraints => { type => 'Set', set => [qw(asc desc ASC DESC)] } },
                { name => 'limit', constraints => ['Integer', { type => 'Range', min => 0, max => 100 }] },
                { name => 'sort' },
            ]
        },
        find_method => 'find',
    };
    my $self_config   = $self->config || {};
    my $parent_config = $self->merge_config_hashes( 
        $c->config->{'ControllerX::ExtJS::REST'} || {}, 
        $c->config->{'ControllerX::Controller::ExtJS::REST'} || {} );

    # merge hashes with right hand precedence
    my $merged_config = $self->merge_config_hashes( $defaults, $self_config );
    $merged_config = $self->merge_config_hashes( $merged_config, $parent_config );

    return $merged_config;
    
}

sub _build_form_base_path {
    my $self = shift;
    return Path::Class::Dir->new( $self->_app->path_to(qw(root forms)) );
}

sub _build_form_base_file {
    my $self = shift;
    my @path = split( /\//, $self->action_namespace );
    return $self->form_base_path->file((pop @path) . '.yml');
}

sub _build_list_base_path {
    my $self = shift;
    return Path::Class::Dir->new( $self->_app->path_to(qw(root lists)) );
}

sub _build_list_base_file {
    my $self = shift;
    my @path = split( /\//, $self->action_namespace );
    my $file = $self->list_base_path->file((pop @path) . '.yml');
    return -e $file ? $file : $self->form_base_file;
}

sub _build_list_options_file {
    my $self = shift;
    my @path = split( /\//, $self->action_namespace );
    my $file = $self->list_base_path->file((pop @path) . '_options.yml');
	return -e $file ? $file : undef;
}

sub _build_default_resultset {
    my ($self, $c) = @_;
    my $class = ref $self;
    my $prefix;
    
    # Copied from Catalyst::Utils
    if($class =~ /^.+?::([MVC]|Model|View|Controller)::(.+)$/ ) {
        $prefix = $2;
    }
    return $prefix;
}

sub clear_caches {
	my ($self) = @_;
	$self->form_config_cache({});
}

sub validate_options {
    my ($self, $c) = @_;
    my $form = HTML::FormFu::ExtJS->new;
    $form->populate($self->_extjs_config->{list_options_validation});
    if($self->list_options_file) {
        $c->log->debug('found configuration file for parameters') if($c->debug);
        $form->load_config_file($self->list_options_file);
    }
    $form->process($c->req->params);
    return $form;
}

sub list {
    my ( $self, $c ) = @_;
	$self->clear_caches if($c->debug);
    my $form = $self->get_form($c, $self->list_base_file);
    my $config = $form->model_config;
    croak "Need resultset and schema" unless($config->{resultset} && $config->{schema});
    my $model = join('::', $config->{schema}, $config->{resultset});
    
    my $validate_options = $self->validate_options($c);
    
    if($validate_options->has_errors) {
        $self->status_bad_request($c, message => 'One ore more parameters did not pass the validation');
        $c->stash->{rest} = { errors => $validate_options->validation_response->{errors} };
        return;
    }

    my $rs = $c->model($model);
    $rs = $self->paging_rs($c, $form, $rs);
    
    # collect rs methods from URI, body and request param
    my @args = map {$_ => [] } @{$c->req->args};
    my $data = $c->req->data;
    if($data && (ref $data eq 'ARRAY') && ref $data->[0] eq 'ARRAY') {
        $data = $data->[0];
        for(my $i = 0; $i < @$data; $i++) {
            my $argv = $data->[$i+1] if(ref $data->[$i+1]);
            $argv = [$argv] unless(ref $argv eq 'ARRAY');
            push(@args, $data->[$i], $argv);
            $i++ if(ref $data->[$i+1]);
        }
    }
    push(@args, map { $_ => [] } $c->req->param('resultset'));
    unshift(@args, $self->_extjs_config->{default_rs_method} => []);
    
    for(my $i = 0; $i < @args; $i+=2) {
        next unless(my $rs_method = $args[$i]);
        my ($m, @params) = split(/,/, $rs_method);
        if($rs_method && DBIx::Class::ResultSet->can($m)) {
            $c->log->warn('Possibly malicious method "'.$m.'" on resultset '.$m.' has not been called');
            next;
        }
        push(@params, @{$args[$i+1]});
        if($rs->can($m)) {
            if($c->debug) {
                my $debug = qq(Calling resultset method $m);
                $debug .= q( with arguments ').join(q(', '), @params).q(') if(@params);
                $c->log->debug($debug);
            }
            $rs = $rs->$m($c, @params);
        } elsif($c->debug) {
            $c->log->debug(qq(Resultset method $m could not be found));
        }
    }
    
    my ($pk, $too_much) = $rs->result_source->primary_columns;
    
    my $grid_data = $form->grid_data([$rs->all], {metaData => {idProperty => $pk, messageProperty => 'message' }});
    if ($self->_extjs_config->{no_list_metadata}) {
        delete $grid_data->{metaData};
    }
    my $count = $rs->search(undef, { rows => undef, offset => undef })->count;
    $grid_data->{results} = $count;
    $self->status_ok( $c, entity => $grid_data);
}

sub paging_rs {
    my ($self, $c, $form, $rs) = @_;
    my $params = $c->req->params;
    
    my $start = abs(int($params->{start} || 0));
    
    my $limit = abs(int($params->{limit} || 0));

    return $rs if($start == 0 && $limit == 0);

    my @direction = grep { $_ eq (lc($params->{dir}) || 'asc') } qw(asc desc);
    my $direction = q{-}.(shift @direction);
    
    my $sort = $params->{sort} || undef;
    
    undef $sort unless($form->get_all_element({ nested_name => $sort }));
    
    my $paged = $rs->search(undef, { offset => $start, rows => $limit || undef});
    my $me = $rs->current_source_alias;
    $paged = $paged->search(undef, { order_by => [ { $direction => join('.', $me, $sort) } ] })
      if $sort;
    return $paged;
}

sub base {
    my ( $self, $c, $id ) = @_;
    $self->object($c, $id);
}


sub object {
    my ( $self, $c, $id ) = @_;
	croak $self->form_base_file." cannot be found" unless(-e $self->form_base_file);
	$self->clear_caches if($c->debug);
    my $config = $self->load_config_file($self->form_base_file);
    $config = { %{$self->_extjs_config->{model_config}}, %{$config->{model_config} || {}} };
    $config->{resultset} ||= $self->default_resultset;
    croak "Need resultset and schema" unless($config->{resultset} && $config->{schema});
    $c->stash->{extjs_formfu_model_config} = $config;

    my $object = $c->model(join('::', $config->{schema}, $config->{resultset}));

    my $req_method = lc($c->req->method);
    
    unless(defined $id || $req_method ne 'put') {
        my ($pk, $too_much) = $object->result_source->primary_columns;
        croak 'Not able to process result classes with multiple primary keys' if($too_much);
        $id = $c->req->param($pk);
    }
    
    if(!defined $id && $req_method eq 'get') {
        $c->forward('list');
        return;
    }
    
    my $guard = $c->model($config->{schema})->txn_scope_guard;
    
    if(my $rs = $self->_extjs_config->{default_rs_method}) {
        if($object->can($rs)) {
            $c->log->debug(qq(Calling default resultset method $rs)) if($c->debug);
            $object = $object->$rs($c);
        } elsif($c->debug) {
            $c->log->debug(qq(Default resultset method $rs cannot be found));
        }
    }

    my $method = $config->{find_method} || $self->_extjs_config->{find_method};
    if (defined $id && defined $object) {
		$object = $object->search( undef, { for => 'update' })
            if($req_method ne 'get');
        $object = $object->$method($id);
        $c->stash->{object} = $object;
    }
	
    $c->stash->{form} =
      $self->get_form($c, $self->path_to_forms($req_method));
    
    if($req_method eq 'get') {
        $c->forward('object_GET');
    } elsif($req_method eq 'post') {
        $c->forward('object_POST');
    } elsif($req_method eq 'put') {
        $c->forward('object_PUT');
    } elsif($req_method eq 'delete') {
        $c->forward('object_DELETE');
    }
    $guard->commit;
}


sub object_PUT {
    my ( $self, $c ) = @_;
    my $object = $c->stash->{object};
    my $form = $c->stash->{form};

    # Check if row object exists
    if(!$c->stash->{object}) {
        $self->status_not_found($c, message => 'Object could not be found.');
        return;
    }

    $self->object_PUT_or_POST($c, $form, $object);
	
	$form->model("DBIC")->default_values($object);
	my $model = $form->model("HashRef");
	$model->flatten(1);
	$model->options(0);
	my $req = { %{$model->create}, %{$c->req->params} }; 
    
    $form->process( $req );
    
    if ( $form->submitted_and_valid ) {
        my $row = $form->model->update($object);
        $self->handle_uploads($c, $row, $form);

        # get values from model
        $self->status_ok( $c, entity => $form->form_data( $row ) );
    }
    else {
        # return form values and error messages
        $self->status_ok( $c, entity => $form->validation_response );
    }
}

sub object_PUT_or_POST {
    my ($self, $c, $form, $object) = @_;

}

sub object_POST {
    my ( $self, $c ) = @_;
    my $form = $c->stash->{form};
    
    $self->object_PUT_or_POST($c, $form);
	
    $form->process( $c->req );

    if ( $form->submitted_and_valid ) {
		my $row = $form->model->create;
        $self->handle_uploads($c, $row, $form);
        
        $c->stash->{object} = $row;
        # get values from model and set the primary key
		my ($pk, $too_much) = $row->result_source->primary_columns;
		my $data = $form->form_data( $row );
		$data->{data}->{$pk} = $row->$pk;
		$self->status_created(
            $c,
            location => $c->uri_for( '', $row->$pk ),
            entity => $data
        );
    
    }
    else {
        # return form values and error messages
        $self->status_ok( $c, entity => $form->validation_response );
    }

}

sub object_GET {
    my ( $self, $c ) = @_;
    my $form = $c->stash->{form};

    $form->process( $c->req );
    
    if($c->stash->{object}) {
        $self->status_ok( $c, entity => $form->form_data( $c->stash->{object} ) );
    } else {
        $self->status_not_found($c, message => 'Object could not be found.');
    }
}

sub object_DELETE {
    my ( $self, $c ) = @_;
    if($c->stash->{object}) {
        $c->stash->{object}->delete;
        $self->status_ok( $c, entity => { message => "Object has been deleted" } );
    } else {
        $self->status_not_found($c, message => 'Object could not be found.');
    }
}


sub path_to_forms {
    my $self = shift;
    my $file = Path::Class::File->new($self->form_base_path . '_' . (shift) . '.yml');
    return -e $file ? $file : $self->form_base_file;
}

sub get_form {
    my ($self, $c, $file) = @_;
	my $form = HTML::FormFu::ExtJS->new();
	$form->query_type('Catalyst');
	my $model_stash = $self->_extjs_config->{model_stash};
	$model_stash->{schema} ||= "DBIC";
	for my $model ( keys %$model_stash ) {
			$form->stash->{$model} = $c->model( $model_stash->{$model} );
	}
	$form->model_config($self->_extjs_config->{model_config});
	
	$file ||= $self->form_base_file;
	my $config = $self->load_config_file($file);
	$form->populate($config);	
    # To allow your form validation packages, etc, access to the catalyst
    # context, a weakened reference of the context is copied into the form's
    # stash.
	
    my $context_stash = $self->_extjs_config->{context_stash};
    $form->stash->{$context_stash} = $c;
    Scalar::Util::weaken( $form->stash->{$context_stash} );
	return $form;
}

sub load_config_file {
	my ($self, $file) = @_;
	my $config;
    unless($config = $self->form_config_cache->{$file . ""}) {
		$config = Config::Any->load_files( {
                    files => [$file],
                    use_ext         => 1,
                    driver_args => { General => { -UTF8 => 1 }, },
        } );
		( undef, $config ) = %{ $config->[0] };
		$self->form_config_cache->{$file.""} = $config;
	}
	return $config;
}

sub handle_uploads {
    my ($self, $c, $row, $form) = @_;
    my $uploads;
    while(my ($k, $v) = each %{$c->req->uploads}) {
        next unless $form->get_field($k);
        $c->log->debug("Cannot handle multiple uploads per field") if($c->debug && ref $v eq "ARRAY");
        $row->$k($v->fh);
    }
    $row->update;
}


sub end {
    my ( $self, $c ) = @_;
    $self->next::method($c);
    if ( $c->req->is_ext_upload ) {
        my $stash_key = (
              $self->config->{'serialize'}
            ? $self->config->{'serialize'}->{'stash_key'}
            : $self->config->{'stash_key'}
          )
          || 'rest';
        my $output;
        eval { $output = JSON::Any->new->encode( $c->stash->{$stash_key} ); };

        $c->res->content_type('text/html');
        $c->res->output( encode_entities($output) );
    }
}

sub _parse_NSPathPart_attr {
    my ( $self, $c ) = @_;
    return ( PathPart => $self->action_namespace );
}


sub _parse_NSListPathPart_attr {
    my ( $self, $c ) = @_;
    if($self->config->{list_namespace}) {
        return ( PathPart => $self->config->{list_namespace} )
    } else {
        my @path = split( /\//, $self->action_namespace );
        $path[-1] = Lingua::EN::Inflect::PL(my $name = $path[-1]);
        $path[-1] = "list_".$path[-1]
          if($name eq $path[-1]);
    
        return ( PathPart => join('/', @path) );
    }
}

1;



=pod

=head1 NAME

CatalystX::Controller::ExtJS::REST - RESTful interface to dbic objects

=head1 VERSION

version 1.101570

=head1 SYNOPSIS

  package MyApp::Controller::User;
  use base qw(CatalystX::Controller::ExtJS::REST);
  
  __PACKAGE__->config({ ... });
  1;
  
  # set the Accept header to 'application/json' globally
  
  Ext.Ajax.defaultHeaders = {
   'Accept': 'application/json'
  };

=head1 DESCRIPTION

This controller will make CRUD operations with ExtJS dead simple. Using REST you can update, create, remove, read and list
objects which are retrieved via L<DBIx::Class>. 

=head1 USAGE

=head2 Set-up Form Configuration

To use this controller, you need to set up at least one configuration file
per controller

If you create a controller C<MyApp::Controller::User>:

  package MyApp::Controller::User;
  
  use Moose;
  extends 'CatalystX::Controller::ExtJS::REST';
  
  1;

You also need to create a file C<root/forms/user.yml>. To a more fine
grained control over object creation, deletion, update or listing, you 
have to create some more files.

  root/
       forms/
             user.yml
             user_get.yml
             user_post.yml
             user_put.yml
       lists/
             user.yml

Only C<root/forms/user.yml> is required. All other files are optional. If ExtJS issues
a GET request, this controller will first try to find the file C<root/forms/user_get.yml>.
If this file does not exist, it will fall back to the so called I<base file>
C<root/forms/user.yml>.

This controller tries to guess the correct model and resultset. The model defaults
to C<DBIC> and the resultset is derived from the name of the controller.
In this example the controller uses the resultset C<< $c->model('DBIC::User') >>.

You can override these values in the form config files:

  ---
    model_config:
      resultset: User
      schema: DBIC
    elements:
      - name: username
      - name: password
      - name: name
      - name: forename
      
  # root/forms/user_put.yml
  # make username and password required an object is created
  ---
    load_config_file: root/forms/user.yml
	constraints:
	  - type: Required
	    name: username
	  - type: Required
	    name: password

Now you can fire up your Catalyst app and you should see two new chained actions:

  Loaded Chained actions:
  ...
  | /users/...                          | /user/list
  | /user/...                           | /user/object

=head2 Accessing objects

To access an object, simply request the controller's url with the desired method.
A C<POST> request to C</user> will create a new user object. The response will include
the id of the new object. You can get the object by requesting C</user/$id> via GET
or remove it by using the C<DELETE> method. 

To update an object, use C<PUT>. PUT is special since it also allows for partial 
submits. This means, that the object is loaded into the form before the request parameters
are applied to it. You only need to send changed columns to the server.

=head2 Accessing a list of objects

You can access L<http://localhost:3000/users> or L<http://localhost:3000/user> to get a list 
of users, which can be used to populate an ExtJS store. 
If you access this URL with your browser you'll get a HTML representation of all users. 
If you access using a XMLHttpRequest using ExtJS the returned
value will be a valid JSON string. Listing objects is very flexible and can easily be extended.
There is also a built-in validation for query parameters. By default the following 
parameters are checked for sane defaults:

=over

=item * dir (either C<asc>, C<ASC>, C<desc> or C<DESC>)

=item * limit (integer, range between 0 and 100)

=item * start (positive integer)

=back

You can extend the validation of parameters by providing an additional file. Place it in
C<root/lists/> and add the suffix C<_options> (e. g. C<root/lists/user_options.yml>). 
You can overwrite or extend the validation configuration there.

Any more attributes you add to the url will result in a call to the corresponding resultset.

  # http://localhost:3000/users/active/
  
  $c->model('DBIC::Users')->active($c)->all;

As you can see, the Catalyst context object is passed as first parameter.
You can even supply arguments to that method using a comma separated list:

  # http://localhost:3000/users/active,arg1,arg2/
  
  $c->model('DBIC::Users')->active($c, 'arg1', 'arg2')->all;

You can chain those method calls to any length. Though, you cannot access resultset method which are
inherited from L<DBIx::Class::ResultSet>. This is a security restriction because
an attacker could call C<http://localhost:3000/users/delete> which will lead to 
C<< $c->model('DBIC::Users')->delete >>. This would remove all rows from C<DBIC::Users>!

To define a default resultset method which gets called every time the controller hits the
result table, set:

  __PACKAGE__->config({default_rs_method => 'restrict'});

This will lead to the following chain:

  # http://localhost:3000/users/active,arg1,arg2/
  
  $c->model('DBIC::Users')->restrict($c)->active($c, 'arg1', 'arg2')->all;

  # same for GET, POST and PUT
  # http://localhost:3000/user/1234
  
  $c->model('DBIC::Users')->restrict($c)->find(1234);

The C<default_rs_method> defaults to the value of L</default_rs_method>. If it is not set 
by the configuration, this controller tries to call C<extjs_rest_$class> (i.e. C<extjs_rest_user>).

=head2 Handling Uploads

This module handles your uploads. If there is an upload and the name of that field
exists in you form config, the column is set to an L<IO::File> object. You need to
handle this on the model side because storing a filehandle will most likely fail.

Fortunately, there are modules out there which can help you with that. Have a look at
L<DBIx::Class::InflateColumn::FS>. Don't use L<DBIx::Class:InflateColumn::File> 
because it is deprecated and broken. 
If you need a more advanced processing of uploaded files, don't hesitate and
overwrite L</handle_uploads>.

=head1 CONFIGURATION

Local configuration:

  __PACKAGE__->config({ ... });  

Global configuration for all controllers which use CatalystX::Controller::ExtJS::REST:

  MyApp->config( {
    CatalystX::Controller::ExtJS::REST => 
      { key => value }
  } );

=head2 find_method

The method to call on the resultset to get an existing row object.
This can be set to the name of a custom function function which is defined with the (custom) resultset class.
It needs to take the primary key as first parameter.

Defaults to C<find>.

=head2 default_rs_method

This resultset method is called on every request. This is useful if you want to 
restrict the resultset, e. g. only find objects which are associated to the
current user.

Nothing is called if the specified method does not exist.

This defaults to C<extjs_rest_[controller namespace]>.

A controller C<MyApp::Controller::User> expects a resultset method
C<extjs_rest_user>.

=head2 context_stash

To allow your form validation packages, etc, access to the catalyst context, 
a weakened reference of the context is copied into the form's stash.

    $form->stash->{context};

This setting allows you to change the key name used in the form stash.

Default value: C<context>

=head2 form_base_path

Defaults to C<root/forms>

=head2 list_base_path

Defaults to C<root/lists>

=head2 no_list_metadata

If set to a true value there will be no meta data send with lists.

Defaults to undef. That means the metaData hash will be send by default.

=head2 model_config

=head3 schema

Defaults to C<DBIC>

=head3 resultset

Defaults to L</default_resultset>

=head2 namespace

Defaults to L<Catalyst::Controller/namespace>

=head2 list_namespace

Defaults to the plural form of L</namespace>. If this is the same as L</namespace> C<list_> is prepended.

=head1 LIMITATIONS

This module is limited to L<HTML::FormFu> as form processing engine,
L<DBIx::Class> as ORM and L<Catalyst> as web application framework.

=head1 PUBLIC ATTRIBUTES

To change the default value of an attribute, either set it as default value

  package MyApp::Controller::MyController;
  use Moose;
  extends 'CatalystX::Controller::ExtJS::REST';
  
  has '+default_result' => ( default => 'MyUser' );

use the config

  __PACKAGE__->config( default_result => 'MyUser' );

or overwrite the builder

  sub _build_default_result { return 'MyUser' };

=head2 default_resultset

Determines the default name of the resultset class from the Model / View or
Controller class if the forms contains no <model_config/resultset> config
value. Defaults to the class name of the controller.

=head2 list_base_path

Returns the path in which form config files for grids will be searched.

=head2 list_base_file

Returns the path to the specific form config file for grids or the default
form config file if the specfic one can not be found.

=head2 path_to_forms

Returns the path to the specific form config file or the default form config
file if the specfic one can not be found.

=head2 form_base_path

=head2 base_path

Returns the path in which form config files will be searched.

=head2 form_base_file

=head2 base_file

Returns the path to the default form config file.

=head1 PUBLIC METHODS

=head2 get_form

Returns a new L<HTML::FormFu::ExtJS> class, sets the model config options and the
request type to C<Catalyst>.

=head2 list

List Action which returns the data for a ExtJS grid.

=head2 handle_uploads

Handles uploaded files by assigning the filehandle to the column accessor of
the DBIC row object.

As an upload field is a regular field it gets set twice. First the filename is set
and C<< $row->update >> is called. This is entirely handled by L<HTML::FormFu::Model::DBIC>.
After that L</handle_uploads> is called which sets the value of a upload field
to the corresponding L<IO::File> object. Make sure you test for that, if you plan to
inflate such a column.

If you want to handle uploads yourself, overwrite L</handle_uploads>

  sub handle_uploads {
      my ($self, $c, $row) = @_;
      if(my $file = c->req->uploads->{upload}) {
          $file->copy_to('yourdestination/'.$filename);
          $row->upload($file->filename);
      }
  }

However, this should to be part of the model.

Since you cannot upload files with an C<XMLHttpRequest>, ExtJS creates an iframe and issues
a C<POST> request in there. If you need to make a C<PUT> request you have to tunnel the
desired method using a hidden field, by using the C<params> config option of 
C<Ext.form.Action.Submit> or C<extraParams> in C<Ext.Ajax.request>. The name of that
parameter has to be C<x-tunneled-method>.

Make sure you do not include a file field in your C<GET> form definition. It will
cause a security error in your browser because it is not allowed set the value of
a file field.

=head2 object

REST Action which returns works with single model entites.

=head2 object_PUT

REST Action to update a single model entity with a PUT request.

=head2 object_POST

REST Action to create a single model entity with a POST request.

=head2 object_PUT_or_POST

Internal method for REST Actions to handle the update of single model entity
with PUT or POST requests.

This method is called before the form is being processed. To add or remove form elements
dynamically, this would be the right place.

=head2 object_GET

REST Action to get the data of a single model entity with a GET request.

=head2 object_DELETE

REST Action to delete a single model entity with a DELETE request.

=head1 PRIVATE ATTRIBUTES

=head2 _extjs_config

This attribute holds the configuration for the controller.
It is created by merging by C<< __PACKAGE__->config >> with the default values.

=head1 PRIVATE METHODS

These methods are private. Please don't overwrite those unless you know what you are doing.

=head2 begin

Run this code before any action in this controller. It sets the C<ActionClass> to L<CatalystX::Action::ExtJS::Deserialize>.
This C<ActionClass> makes sure that no deserialization happens if the body's content is a file upload.

=head2 end

If the request contains a file upload field, extjs expects the json response to be serialized and 
returned in a document with the C<Content-type> set to C<text/html>.

=head2 _parse_NSPathPart_attr

=head2 _parse_NSListPathPart_attr

=head1 CONTRIBUTORS

  Mario Minati

=head1 AUTHOR

  Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__


