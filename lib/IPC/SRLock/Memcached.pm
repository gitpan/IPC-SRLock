package IPC::SRLock::Memcached;

use namespace::autoclean;

use Moo;
use Cache::Memcached;
use File::DataClass::Types qw( ArrayRef NonEmptySimpleStr Object );
use Time::HiRes            qw( usleep );

extends q(IPC::SRLock::Base);

# Public attributes
has 'lockfile' => is => 'ro', isa => NonEmptySimpleStr, default => '_lockfile';

has 'servers'  => is => 'ro', isa => ArrayRef,
   default     => sub { [ 'localhost:11211' ] };

has 'shmfile'  => is => 'ro', isa => NonEmptySimpleStr, default => '_shmfile';

# Private attributes
has '_memd'    => is => 'lazy', isa => Object, builder => sub {
   Cache::Memcached->new( debug     => $_[ 0 ]->debug,
                          namespace => $_[ 0 ]->name,
                          servers   => $_[ 0 ]->servers ) },
   init_arg    => undef, reader => 'memd';

# Private methods
sub _list {
   my $self = shift; my $list = []; my $start = time;

   while (1) {
      if ($self->memd->add( $self->lockfile, 1, $self->patience + 30 )) {
         my $recs = $self->memd->get( $self->shmfile ) || {};

         $self->memd->delete( $self->lockfile );

         for my $key (sort keys %{ $recs }) {
            my @fields = split m{ , }mx, $recs->{ $key };

            push @{ $list }, { key     => $key,
                               pid     => $fields[ 0 ],
                               stime   => $fields[ 1 ],
                               timeout => $fields[ 2 ] };
         }

         return $list;
      }

      $self->_sleep_or_throw( $start, time, $self->lockfile );
   }

   return;
}

sub _reset {
   my ($self, $key) = @_; my $start = time;

   while (1) {
      if ($self->memd->add( $self->lockfile, 1, $self->patience + 30 )) {
         my $recs = $self->memd->get( $self->shmfile ) || {}; my $found = 0;

         delete $recs->{ $key } and $found = 1;
         $found and $self->memd->set( $self->shmfile, $recs );
         $self->memd->delete( $self->lockfile );
         $found or $self->throw( 'Lock [_1] not set', args => [ $key ] );
         return 1;
      }

      $self->_sleep_or_throw( $start, time, $self->lockfile );
   }

   return;
}

sub _set {
   my ($self, $args) = @_; my $start = time;

   my $key = $args->{k}; my $pid = $args->{p}; my $timeout = $args->{t};

   while (1) {
      my $now = time; my ($lock_set, $rec);

      if ($self->memd->add( $self->lockfile, 1, $self->patience + 30 )) {
         my $recs = $self->memd->get( $self->shmfile ) || {};

         if ($rec = $recs->{ $key }) {
            my @fields = split m{ , }mx, $rec;

            if ($now > $fields[ 1 ] + $fields[ 2 ]) {
               $recs->{ $key } = "${pid},${now},${timeout}";
               $self->memd->set( $self->shmfile, $recs );

               my $text = $self->timeout_error
                  ( $key, $fields[ 0 ], $fields[ 1 ], $fields[ 2 ] );

               $self->log->error( $text ); $lock_set = 1;
            }
         }
         else {
            $recs->{ $key } = "${pid},${now},${timeout}";
            $self->memd->set( $self->shmfile, $recs );
            $lock_set = 1;
         }

         $self->memd->delete( $self->lockfile );

         if ($lock_set) {
            $self->log->debug( "Lock ${key} set by ${pid}" );
            return 1;
         }
         elsif ($args->{async}) { return 0 }
      }

      $self->_sleep_or_throw( $start, $now, $self->lockfile );
   }

   return;
}

sub _sleep_or_throw {
   my ($self, $start, $now, $key) = @_;

   $self->patience and $now > $start + $self->patience
      and $self->throw( 'Lock [_1] timed out', args => [ $key ] );
   usleep( 1_000_000 * $self->nap_time );
   return;
}

1;

__END__

=pod

=head1 Name

IPC::SRLock::Memcached - Set/reset locks using libmemcache

=head1 Synopsis

   use IPC::SRLock;

   my $config = { type => q(memcached) };

   my $lock_obj = IPC::SRLock->new( $config );

=head1 Description

Uses L<Cache::Memcached> to implement a distributed lock manager

=head1 Configuration and Environment

This class defines accessors for these attributes:

=over 3

=item C<lockfile>

Name of the key to the lock file record. Defaults to C<_lockfile>

=item C<servers>

An array ref of servers to connect to. Defaults to C<localhost:11211>

=item C<shmfile>

Name of the key to the lock table record. Defaults to C<_shmfile>

=back

=head1 Subroutines/Methods

=head2 _list

List the contents of the lock table

=head2 _reset

Delete a lock from the lock table

=head2 _set

Set a lock in the lock table

=head2 _sleep_or_throw

Sleep for a bit or throw a timeout exception

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Cache::Memcached>

=item L<File::DataClass>

=item L<IPC::SRLock::Base>

=item L<Moo>

=item L<Time::HiRes>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2014 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
