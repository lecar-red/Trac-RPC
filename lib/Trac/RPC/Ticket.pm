package Trac::RPC::Ticket;

=encoding UTF-8
=cut

=head1 NAME

Trac::RPC::Ticket - access to Trac Ticket methods via Trac XML-RPC Plugin

=cut

use strict;
use warnings;

use DateTime;
use Params::Validate qw( validate );
use Carp; # change over to Exception::Class throw

use base qw(Trac::RPC::Base);

=head1 METHODS 

=head2 get_ticket
 
 * Get: ticket
 * Return: array ref:
    [ 'ticket #', time_created, time_changed, attributes

=cut

sub get_ticket {
    my $self = shift;

    return $self->call('ticket.get', RPC::XML::int->new(shift));
}

=head2 query_ticket (or should it be tickets)

  * string query, example: "user=me"
  * Return: array ref of tickets that matched

=cut

sub query_ticket {
    my $self = shift;

    return $self->call('ticket.query', RPC::XML::string->new(shift));
}

=head2 create_ticket

create ticket is a bit more complex than other calls.

Parameters:

=over 

=item * summary - text ticket summary

=item * description - text ticket description (can be large-ish)

=item * attributes  - hash ref with various keys (need to define somewhere)

=item * notfy - boolean flag to notify when created or not

=item * when - datetime (default: now)

=back

Ticket Attributes (might be generic)

=over 

=item * type - defect, enhancement, task (or as defined)

=item * priority - block, critical, major, minor, trival

=item * component - as defined in system

=item * milestone - as defined in system

=item * version 

=item * keywords

=item * cc

=item * owner

=back

=cut 

sub create_ticket {
    my $self = shift;
    my %p    = validate @_, {
        summary     => 1,
        description => 1,
        attributes  => 1, # struct, need to validate keys
        notfy       => 1, # boolean
        when        => {
            default  => DateTime->now,
            optional => 1,
        },
    };

    return $self->call('ticket.create', 
        RPC::XML::string->new( $p{summary} ),
        RPC::XML::string->new( $p{description} ),
        RPC::XML::struct->new( $p{attributes} ),
        RPC::XML::boolean->new( $p{notify} ),
        RPC::XML::datetime_iso8601->new( $p{when} )
    );
}

=head2 update_ticket

Updates ticket 

=over

=item * id - ticket id (required)

=item * comment - comment

=item * attributes - hash reference to ticket attributes

=item * notify - boolean (default: false)

=item * author - trac user (default: logged in user)

=item * when   - DateTime object (default: now)

=back

=cut
sub update_ticket {
    my $self = shift;
    my %p    = validate @_, {
        id      => 1, # ticket id
        comment => 0,
        # not sure this is right, might need to leave out for noop
        attributes => { default => {} },
        notify  => { default => 0 },
        author  => { default => $self->{user} },
        # action or _ts is kind of required-ish
        when    => { default => DateTime->now },
    };

    return $self->call('ticket.update',
        RPC::XML::int->new( $p{id} ),
        RPC::XML::string->new( $p{comment} ),
        RPC::XML::struct->new( $p{attributes} ),
        RPC::XML::boolean->new( $p{notify} ),
        RPC::XML::string->new( $p{author} ),
        RPC::XML::datetime_iso8601->new( $p{when} )
    );
}

=head2 get_ticket_fields

returns: array of hashes for each ticket fields, some are used for attributes
and some are in the body of the create/update

=cut

sub get_ticket_fields {
    my $self = shift;
    
    return $self->call('ticket.getTicketFields');
}

=head2 get_ticket_actions( id )

returns: array of actions available on a ticket

=cut 
sub get_ticket_actions {
    my $self = shift;
    my $id   = shift || croak "Missing required ticket id"; # change to throw

    return $self->call('ticket.getActions', RPC::XML::int->new( $id ));
}


1;
