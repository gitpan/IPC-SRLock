# @(#)$Id: Fcntl.pm 150 2010-09-22 18:44:19Z pjf $

package IPC::SRLock::Fcntl;

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.5.%d', q$Rev: 150 $ =~ /\d+/gmx );
use parent qw(IPC::SRLock);

use Data::Serializer;
use File::Spec;
use File::Spec::Functions;
use Fcntl qw(:flock);
use IO::AtomicFile;
use IO::File;
use Time::HiRes qw(usleep);
use Try::Tiny;

my %ATTRS = ( lockfile   => undef,
              mode       => oct q(0666),
              serializer => undef,
              shmfile    => undef,
              tempdir    => File::Spec->tmpdir,
              umask      => 0, );

__PACKAGE__->mk_accessors( keys %ATTRS );

# Private methods

sub _init {
   my $self = shift; my $path;

   for (grep { !defined $self->{ $_ } } keys %ATTRS) {
      $self->{ $_ } = $ATTRS{ $_ };
   }

   unless ($self->lockfile) {
      $path = catfile( $self->tempdir, $self->name.q(.lck) );
      $self->lockfile( $path =~ m{ \A ([ -\.\/\w.]+) \z }mx ? $1 : q() );
   }

   unless ($self->shmfile) {
      $path = catfile( $self->tempdir, $self->name.q(.shm) );
      $self->shmfile( $path =~ m{ \A ([ -\.\/\w.]+) \z }mx ? $1 : q() );
   }

   $self->serializer( Data::Serializer->new( serializer => q(Storable) ) );
   return;
}

sub _list {
   my $self = shift; my $list = [];

   my ($lock_file, $lock_ref) = $self->_read_shmfile;

   while (my ($key, $hash) = each %{ $lock_ref }) {
      push @{ $list }, { key     => $key,
                         pid     => $hash->{spid},
                         stime   => $hash->{stime},
                         timeout => $hash->{timeout} };
   }

   $self->_release( $lock_file );
   return $list;
}

sub _read_shmfile {
   my $self = shift; my ($e, $lock, $ref);

   umask $self->umask;

   unless ($lock = IO::File->new( $self->lockfile, q(w), $self->mode )) {
      $self->throw( error => 'File [_1] cannot write',
                    args  => [ $self->lockfile ] );
   }

   flock $lock, LOCK_EX;

   if (-f $self->shmfile) {
      try   { $ref = $self->serializer->retrieve( $self->shmfile ) }
      catch { $self->_release( $lock ); $self->throw( $_ ) };
   }
   else { $ref = {} }

   return ($lock, $ref);
}

sub _release {
   my ($self, $lock) = @_; flock $lock, LOCK_UN; $lock->close; return;
}

sub _reset {
   my ($self, $key) = @_; my ($lock_file, $lock_ref) = $self->_read_shmfile;

   unless (exists $lock_ref->{ $key }) {
      $self->_release( $lock_file );
      $self->throw( error => 'Lock [_1] not set', args => [ $key ] );
   }

   delete $lock_ref->{ $key };
   $self->_write_shmfile( $lock_file, $lock_ref );
   return 1;
}

sub _set {
   my ($self, $key, $pid, $timeout) = @_;
   my ($lock, $lock_file, $lock_ref, $now, $start);

   $lock_ref = {}; $start = time;

   while (!$now || $lock_ref->{ $key }) {
      ($lock_file, $lock_ref) = $self->_read_shmfile; $now = time;

      if (($lock = $lock_ref->{ $key })
          && ($now > $lock->{stime} + $lock->{timeout})) {
         $self->log->error( $self->timeout_error( $key,
                                                  $lock->{spid   },
                                                  $lock->{stime  },
                                                  $lock->{timeout} ) );
         delete $lock_ref->{ $key };
         $lock = 0;
      }

      if ($lock) {
         $self->_release( $lock_file );

         if ($self->patience && $now - $start > $self->patience) {
            $self->throw( error => 'Lock [_1] timed out', args => [ $key ] );
         }

         usleep( 1_000_000 * $self->nap_time );
      }
   }

   $lock_ref->{ $key } = { spid    => $pid,
                           stime   => $now,
                           timeout => $timeout };
   $self->_write_shmfile( $lock_file, $lock_ref );
   $self->log->debug( "Lock $key set by $pid\n" ) if ($self->debug);
   return 1;
}

sub _write_shmfile {
   my ($self, $lock_file, $lock_ref) = @_; my ($e, $wtr);

   unless ($wtr = IO::AtomicFile->new( $self->shmfile, q(w), $self->mode )) {
      $self->_release( $lock_file );
      $self->throw( error => 'File [_1] cannot write',
                    args  => [ $self->shmfile ] );
   }

   try   { $self->serializer->store( $lock_ref, $wtr ) }
   catch { $wtr->delete; $self->_release( $lock_file ); $self->throw( $_ ) };

   $wtr->close; $self->_release( $lock_file );
   return;
}

1;

__END__

=pod

=head1 Name

IPC::SRLock::Fcntl - Set/reset locks using fcntl

=head1 Version

0.5.$Revision: 150 $

=head1 Synopsis

   use IPC::SRLock;

   my $config   = { tempdir => q(path_to_tmp_directory), type => q(fcntl) };

   my $lock_obj = IPC::SRLock->new( $config );

=head1 Description

Uses L<Fcntl> to lock access to a disk based file which is
read/written by L<Data::Serializer>. This is the default type for
L<IPC::SRLock>.

=head1 Configuration and Environment

This class defines accessors and mutators for these attributes:

=over 3

=item lockfile

Path to the file used by fcntl

=item mode

File mode to use when creating the lock table file. Defaults to 0666

=item shmfile

Path to the lock table file

=item tempdir

Path to the directory where the lock files reside. Defaults to
C<File::Spec-E<gt>tmpdir>

=item umask

The umask to set when creating the lock table file. Defaults to 0

=back

=head1 Subroutines/Methods

=head2 _init

Initialise the object

=head2 _list

List the contents of the lock table

=head2 _read_shmfile

Read the file containing the lock table from disk

=head2 _release

Release the exclusive flock on the lock file

=head2 _reset

Delete a lock from the lock table

=head2 _set

Set a lock in the lock table

=head2 _write_shmfile

Write the lock table to the disk file

=head1 Diagnostics

None

=head1 Dependencies

=over 4

=item L<IPC::SRLock>

=item L<Data::Serializer>

=item L<IO::AtomicFile>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <Support at RoxSoft.co.uk> >>

=head1 License and Copyright

Copyright (c) 2008 Peter Flanigan. All rights reserved

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
