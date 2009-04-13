package MooseX::MultiMethods::Meta::Method;

use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw/CodeRef/;
use Devel::PartialDump qw/dump/;
use aliased 'MooseX::Types::VariantTable';

use namespace::autoclean;

extends 'Moose::Object', 'Moose::Meta::Method';

has _variant_table => (
    is      => 'ro',
    isa     => VariantTable,
    default => sub { VariantTable->new },
    handles => [qw/add_variant/],
);

has body => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    builder => 'initialize_body',
);

method initialize_body {
    my $name          = $self->name;
    my $variant_table = $self->_variant_table;

    return sub {
        my ($args) = \@_;

        if (my ($result, $type) = $variant_table->find_variant($args)) {
            my $method = $result->body;
            goto $method;
        }

        confess "no variant of method '${name}' found for ", dump($args);
    };
}

1;
