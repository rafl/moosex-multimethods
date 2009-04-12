package MooseX::MultiMethods;

use Moose;
use Devel::Declare ();
use MooseX::Method::Signatures;
use Sub::Install qw/install_sub/;
use MooseX::Types::Moose qw/HashRef ClassName/;
use aliased 'Devel::Declare::Context::Simple' => 'DDContext';
use aliased 'MooseX::MultiMethods::Meta::Method' => 'MetaMethod';

use namespace::autoclean;

has _dd_context => (
    is      => 'ro',
    isa     => DDContext,
    lazy    => 1,
    builder => '_build_dd_context',
    handles => qr/.*/,
);

has _dd_init_args => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

has class => (
    is       => 'ro',
    isa      => ClassName,
    required => 1,
);

method BUILD ($args) {
    $self->_dd_init_args($args);
}

method _build_dd_context {
    return DDContext->new(%{ $self->_dd_init_args });
}

method import (ClassName $class:) {
    my $setup_class = caller;
    $class->setup_for($setup_class);
}

method setup_for (ClassName $class: ClassName $setup_class, HashRef $args = {}) {
    Devel::Declare->setup_for($setup_class, {
        'multi' => {
            const => sub {
                my $self = $class->new({ class => $setup_class, %{ $args } });
                $self->init(@_);
                return $self->parse;
            },
        },
    });

    install_sub({
        code => sub {},
        into => $setup_class,
        as   => 'multi',
    });

    MooseX::Method::Signatures->setup_for($setup_class);
}

method parse {
    $self->skip_declarator;
    $self->skipspace;

    my $thing = $self->strip_name;
    confess "expected 'method', got '${thing}'"
        unless $thing eq 'method';

    $self->skipspace;

    my $name = $self->strip_name;
    confess "anonymous multi methods not allowed"
        unless defined $name && length $name;

    my $linestr = $self->get_linestr;
    substr($linestr, $self->offset, 0, 'method');
    $self->set_linestr($linestr);

    my $meta = Class::MOP::class_of($self->class);
    my $meta_method = $meta->get_method($name);
    unless ($meta_method) {
        $meta_method = MetaMethod->new(
            name         => $name,
            package_name => $self->class,
        );
        $meta->add_method($name => $meta_method);
    }

    confess "method '${name}' is already defined"
        unless $meta_method->isa(MetaMethod);

    $self->shadow(sub {
        my ($method) = @_;
        $meta_method->add_variant($method->type_constraint => $method);
    });
}

1;
