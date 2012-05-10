# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::Aliases;
use MooseX::Types::Moose qw(Str Bool);

use Pinto::Types qw(ArrayRefOfPkgsOrDists);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => ArrayRefOfPkgsOrDists,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has stack => (
    is       => 'ro',
    isa      => Str,
    alias    => 'operative_stack',
);


has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has norecurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Operator Pinto::Role::PackageImporter );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->_execute($_, $stack) for $self->targets;

    return $self->result;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $target, $stack) = @_;

    my ($dist, $did_pull) = $self->repos->get_or_pull( target => $target,
                                                       stack  => $stack );
    return if not $dist;

    unless ( $self->norecurse ) {
        my @prereq_dists = $self->repos->pull_prerequisites( dist  => $dist,
                                                             stack => $stack );
        $did_pull += @prereq_dists;
    }

    $self->result->changed if $did_pull;

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
