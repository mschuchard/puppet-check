# syntax error at 'end of file' instead of line or line and col
class foo {
  file { 'bar': ensure => file
}
