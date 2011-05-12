//Custom maps functions for kassi
 function bitch(){
        alert("test");
    }

    var initialLocation;
    var map;
    var test = "test";
    var helsinki;
    var browserSupportFlag =  new Boolean();
    var markersArr = [];   // Array for keeping track of markers on map
    var listing_category = ["all"];
    var listing_sharetypes = ["all"];


    function initialize() {
      helsinki = new google.maps.LatLng(60.2, 24.9);
      var myOptions = {
        zoom: 10,
        mapTypeId: google.maps.MapTypeId.ROADMAP
      };
      map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);

      // Try W3C Geolocation (Preferred)
      if(navigator.geolocation) {
        browserSupportFlag = true;
        navigator.geolocation.getCurrentPosition(function(position) {
          initialLocation = new google.maps.LatLng(position.coords.latitude,position.coords.longitude);
          map.setCenter(initialLocation);
        }, function() {
          handleNoGeolocation(browserSupportFlag);
        });
      // Try Google Gears Geolocation
      } else if (google.gears) {
        browserSupportFlag = true;
        var geo = google.gears.factory.create('beta.geolocation');
        geo.getCurrentPosition(function(position) {
          initialLocation = new google.maps.LatLng(position.latitude,position.longitude);
          map.setCenter(initialLocation);
        }, function() {
          handleNoGeoLocation(browserSupportFlag);
        });
      // Browser doesn't support Geolocation
      } else {
        browserSupportFlag = false;
        handleNoGeolocation(browserSupportFlag);
      }

      function handleNoGeolocation(errorFlag) {
        if (errorFlag == true) {
          alert("Geolocation service failed.");
          initialLocation = helsinki;
        } else {
          alert("Your browser doesn't support geolocation. We've placed you in Helsinki.");
          initialLocation = helsinki;
        }
        map.setCenter(initialLocation);
      }
      //addListingsMarkers();
      google.maps.event.addListenerOnce(map, 'tilesloaded', addListingMarkers);
      // 'bounds_changed' event will fire continuously while the map is being panned so we need a timeout
      // to wait for idle moment (otherwise the server will be bombarded with requests)
      google.maps.event.addListener(map, 'bounds_changed', (function() {
          var timer;
          return function() {
            clearTimeout(timer);
            timer = setTimeout(function() {
                // Update markers on the map
                addListingMarkers();
            }, 500);
          }
      })());
    }


    function addListingMarkers() {
      // Test requesting location data
      // Now the request_path needs to also have a query string with the wanted parameters
      var bounds = map.getBounds();
      var sw = bounds.getSouthWest();
      var ne = bounds.getNorthEast();
      
      var request_path = '/api/query'
    	$.get(request_path, { listing_type: listing_type, 'category[]': listing_category, 'share_type[]': listing_sharetypes,
    	                      bounds_sw: sw.lat().toString() + '|' + sw.lng().toString(),
    	                      bounds_ne: ne.lat().toString() + '|' + ne.lng().toString() }, function(data) {

    	  var info = data.info
    	  var data_arr = data["data"];
    	  var infowindow = new google.maps.InfoWindow();
    	  var directionsService = new google.maps.DirectionsService();
          var directionsDisplay = new google.maps.DirectionsRenderer();
          directionsDisplay.setOptions( { suppressMarkers: true } );
          var flagMarker = new google.maps.Marker();
          var markers = [];
          var markerContents = [];
          var showingMarker = [];
    		for (i in data_arr) {
    		  (function() {
    		    var entry = data_arr[i];
    		    if (entry["location"]) { //////////
        		var location = new google.maps.LatLng(entry["location"]["latitude"], entry["location"]["longitude"]);

            var contentString = '<div style="background-color:#F7F5E6">'+info[i]+'</div>';
            var marker = new google.maps.Marker({
              position: location,
              title: entry["title"],
             // map: map,
              icon: '/images/map_icons/'+entry["category"]+'_'+entry["listing_type"]+'.png'
            });
            markers.push(marker);
            markersArr.push(marker);
            showingMarker.push(false);
            markerContents.push(contentString);
            google.maps.event.addListener(marker, 'click', function() {
              infowindow.close();
              directionsDisplay.setMap(null);
              flagMarker.setOptions({map:null});
              if (showingMarker[i])
                showingMarker[i] = false;
              else {
                showingMarker.forEach(function(infoshow) { infoshow = false; });
                showingMarker[i] = true;
                infowindow.setContent(contentString);
                infowindow.open(map,marker);

                if (entry["category"]=="rideshare") {
                  var end = new google.maps.LatLng(entry["destination"]["latitude"], entry["destination"]["longitude"]);
                  var request = {
                    origin:location,
                    destination:end,
                    travelMode: google.maps.DirectionsTravelMode.DRIVING
                  };
                  directionsDisplay.setMap(map);
                  directionsService.route(request, function(response, status) {
                    if (status == google.maps.DirectionsStatus.OK) {
                      directionsDisplay.setDirections(response);
                    }
                  });
                  flagMarker.setOptions({
                    position: end,
                    map: map,
                    icon: '/images/map_icons/flag_rideshare.png'
                  });
                }
              }
            });
            google.maps.event.addListener(infowindow, 'closeclick', function() {
              showingMarker.forEach(function(infoshow) { infoshow = false; });
            });
          } ///////////////////////////////////////
          })();
        }
        var markerCluster = new MarkerClusterer(map, markers, markerContents, infowindow, showingMarker, {
        imagePath: '/images/map_icons/group_'+listing_type});
    	});
    }

    function clearMarkers() {
        if (markersArr) {
            for (i in markersArr) {
                markersArr[i].setMap(null);
            }
        }
    }


    // Simple callback for passing filter changes to the mapview
    function filtersUpdated(category, sharetypes) {
        //alert("update filters!!!!");
        listing_category = category;
        listing_sharetypes = sharetypes;
        clearMarkers();
        addListingMarkers();
    }

    //google.maps.event.addDomListener(window, 'load', initialize);
