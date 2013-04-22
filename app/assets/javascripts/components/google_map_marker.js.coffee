class @GoogleMapMarker

  @getMarkerOptions: ->
    {hover:
      image: new google.maps.MarkerImage(
        '/assets/google-maps/marker-images/hover-2x.png',
        new google.maps.Size(40,57),
        new google.maps.Point(0,0),
        new google.maps.Point(10,29),
        new google.maps.Size(20,29)
      )

      shape:
        coord: [14,0,15,1,16,2,17,3,18,4,18,5,19,6,19,7,19,8,19,9,19,10,19,11,19,12,19,13,18,14,18,15,17,16,17,17,16,18,16,19,15,20,14,21,14,22,13,23,13,24,12,25,11,26,11,27,8,27,7,26,7,25,6,24,6,23,5,22,4,21,4,20,3,19,3,18,2,17,2,16,1,15,0,14,0,13,0,12,0,11,0,10,0,9,0,8,0,7,0,6,0,5,1,4,1,3,2,2,3,1,5,0,14,0],
        type: 'poly'

    default:
      image: new google.maps.MarkerImage(
        '/assets/google-maps/marker-images/default-2x.png',
        new google.maps.Size(40,57),
        new google.maps.Point(0,0),
        new google.maps.Point(10,29),
        new google.maps.Size(20,29)
      )

      shape:
        coord: [14,0,15,1,16,2,17,3,18,4,18,5,19,6,19,7,19,8,19,9,19,10,19,11,19,12,19,13,18,14,18,15,17,16,17,17,16,18,16,19,15,20,14,21,14,22,13,23,13,24,12,25,11,26,11,27,8,27,7,26,7,25,6,24,6,23,5,22,4,21,4,20,3,19,3,18,2,17,2,16,1,15,0,14,0,13,0,12,0,11,0,10,0,9,0,8,0,7,0,6,0,5,1,4,1,3,2,2,3,1,5,0,14,0]
        type: 'poly'
    }
