package Mojo::Channel::WebSocket;

use Mojo::Base 'Mojo::Channel::HTTP';

has [qw/ioloop tx/];

sub read {
  my ($self, $chunk) = @_;
  my $tx = $self->tx;

  $tx->{read} .= $chunk // '';
  while (my $frame = $tx->parse_frame(\$tx->{read})) {
    $tx->finish(1009) and last unless ref $frame;
    $tx->emit(frame => $frame);
  }

  $tx->emit('resume');
}

sub write {
  my $self = shift;
  my $tx = $self->tx;

  unless (length($tx->{write} // '')) {
    $tx->{state} = $tx->{finished} ? 'finished' : 'read';
    $tx->emit('drain');
  }

  return delete $tx->{write} // '';
}

1;

