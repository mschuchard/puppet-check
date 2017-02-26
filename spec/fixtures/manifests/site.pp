node good.example.com {
  notify { 'hello world': }
}

node syntax_error.example.com {
  notify { 'goodbye world' }
}
