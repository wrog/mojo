package Mojo::Channel::HTTP::Client;

use Mojo::Base 'Mojo::EventEmitter';

has [qw/ioloop tx/];

1;

