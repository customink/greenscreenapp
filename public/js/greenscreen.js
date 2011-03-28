yepnope([{
  test : isNaN(new Date("2011-01-01T00:00:00-05:00").getTime()),
  yep : ['/js/iso8601_support.js'],
  complete : function() {

      $('time').each(function(i, el) {
        $el = $(el);

        var ts = new Date(Date.parse(el.getAttribute('datetime')));
        $el.html( $el.time_ago_in_words_with_parsing( ts ) ).removeClass('invisible');
      });

      var $ok = $('#ok');
      if($ok.length > 0) {
        var w = $ok.width();
        $ok.width( w > 1000 ? 1000 : w ).bigtext(); // bigtext() doesn't work very well with full-width elements
      }

  }
}]);
