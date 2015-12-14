package Mojo::Channel::HTTP::Client;

use Mojo::Base 'Mojo::EventEmitter';

use Mojo::Util 'term_escape';
use Scalar::Util 'weaken';

use constant DEBUG => $ENV{MOJO_USERAGENT_DEBUG};

has [qw/ioloop tx/];

sub read {
  my ($self, $id, $chunk) = @_;
  return unless my $tx = $self->tx;

  # Process incoming data
  warn term_escape "-- Client <<< Server (@{[_url($tx)]})\n$chunk\n" if DEBUG;
  $tx->client_read($chunk);
  if    ($tx->is_finished) { $self->emit(finished => $id) }
  elsif ($tx->is_writing)  { $self->write($id) }
}

sub write {
  my ($self, $id) = @_;
  return unless my $tx = $self->tx;
  return if !$tx->is_writing || $self->{writing}++;
  my $chunk = $tx->client_write;
  delete $self->{writing};
  warn term_escape "-- Client >>> Server (@{[_url($tx)]})\n$chunk\n" if DEBUG;
  my $stream = $self->ioloop->stream($id)->write($chunk);
  $self->emit(finished => $id) if $tx->is_finished;

  # Continue writing
  return unless $tx->is_writing;
  weaken $self;
  $stream->write('' => sub { $self->write($id) if $self });
}

sub _url { shift->req->url->to_abs }

1;

