$(function() {
  $('time').each(function(i, el) {
    $el = $(el);
    var ts = new Date(el.getAttribute('datetime'));
    $el.html( $el.time_ago_in_words_with_parsing( ts ) ).removeClass('invisible');
  });

  var $ok = $('#ok');
  if($ok.length > 0) {
    var w = $ok.width();
    $ok.width( w > 1000 ? 1000 : w ).bigtext(); // bigtext() doesn't work very well with full-width elements
  }
});