package App::Syndicator::TextDraw;
use MooseX::Declare;

role App::Syndicator::TextDraw {
    use Term::ANSIColor;

    method d_error (@arg ) {    
        print  color('red'), @arg, color('reset'), "\n";
    }

    method d_feed_title (@arg) {
        print  color('bold blue'), @arg , color('reset'), "\n";
    }
    method d_title (@arg) {
        print  color('bold white'), @arg , color('reset'), "\n";
    }

    method d_say (@arg) {
        print color('white'), @arg, color('reset'), "\n";
    }

    method d_link (@arg) {
        print  color('green'), @arg , color('reset'), "\n";
    }

    method d_hr (@arg) {
        print  '-' x 80, "\n";
    }
}

1;
