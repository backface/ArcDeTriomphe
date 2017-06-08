//
// Copyright 2017 Michael Aschauer
//

using Toybox.Application as App;

class ArcDeTriompheWatch extends App.AppBase
{
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [new ArcDeTriompheView()];
    }

}
