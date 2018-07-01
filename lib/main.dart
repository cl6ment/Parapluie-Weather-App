//flutter package
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

//dart native package
import 'dart:async';
import 'dart:core';
import 'dart:convert';

//Allow the app to run
//Syntactic Sugar: void main() => runApp(HomePage());
void main() {
  runApp(
    MaterialApp(
      title: 'Parapluie',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: HomePage()
    )
  );
}

//Define the HomePage and allow us to use the methodes from the Statefull widget class
class HomePage extends StatefulWidget {
  @override
  createState() => new HomePageState();//We create a new state for our application
}

class CurrentWeather {

  String temp;
  String tMax;
  String tMin;
  String windSpeed;
  String cond;
  String windDir;
  String uv;
  String visi;
  String rainproba;
  String rainIntens;
  String pressure;
  String icon;

  CurrentWeather({
    this.temp='N/A',
    this.tMax='N/A',
    this.tMin='N/A',
    this.cond='N/A',
    this.windDir='N/A',
    this.windSpeed='N/A',
    this.pressure='N/A',
    this.rainIntens='N/A',
    this.rainproba='N/A',
    this.uv='N/A',
    this.visi='N/A',
    this.icon='N/A'
    });
}

class DailyForecast {

  String cond;
  String tMax;
  String tMin;
  String uv;
  String windSpeed;
  String visi;
  String rainProba;
  String icon;

  DailyForecast({
    this.cond='N/A',
    this.rainProba='N/A',
    this.tMax='N/A',
    this.tMin='N/A',
    this.uv='N/A',
    this.visi='N/A',
    this.windSpeed='N/A',
    this.icon='N/A'
  });
}

//convert the current timestamp to a human readable date
class TimeToString {

  var today = new DateTime.now();

  List <String> dateString = new List.filled(6, 'N/A');
  List <String> days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  TimeToString() {
    for(int i=0; i<5; i++){
      this.today = today.add(new Duration(days: 1));
      this.dateString[i] = days[today.weekday-1];
    }
    today = new DateTime.now();
  }

  List <String> convert(){
    return this.dateString;
  }

}


//Here we define the new state
class HomePageState extends State<HomePage> {

  CurrentWeather cw = new CurrentWeather();
  List <DailyForecast> df = new List.filled(5, new DailyForecast(), growable: true);
  Map<String, double> _startLocation;
  String cityName = 'unknown';
  Map <String, int> weatherIcons = {
    'clear-day': 0xf00d,
    'clear-night': 0xf02e,
    'rain': 0xf008,
    'snow': 0xf00a,
    'sleet': 0xf0b4,
    'wind': 0xf012,
    'fog': 0xf003,
    'cloudy': 0xf013,
    'partly-cloudy-day': 0xf002,
    'partly-cloudy-night': 0xf031,
    'default':0xf07b,
    'rain-proba':0xf04e,
    'wind-speed':0xf050,
    'wind-dir':0xf0b1,
    'temp-min':0xf053,
    'temp-max':0xf055
  };


  Future <Null> getLocation() async {

    Map <String, double> location;
    Location _location = new Location();

    try{
      location = await _location.getLocation;
    } catch (e) {
      _location = null;
      
    }
    
    setState(() {
        _startLocation = location;
    });

  }


  Future<Null> getCityName(String lat, String lon) async {

    final apiKey = "API_KEY";
    final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng="+lat+","+lon+"&key="+apiKey;

    http.Response response = await http.get(Uri.encodeFull(url));

    if(response.statusCode == 200) {
      var data = json.decode(response.body);

      setState(() {

        if(data['results'][0]['address_components'][2]['long_name'] != null){
          cityName = data['results'][0]['address_components'][2]['long_name'];
        }

      });
    }
  }
  

  Future<Null> getWeatherData() async {

    final apiKey = "API_KEY";

    String lat = '';
    String lon = '';

    await this.getLocation();

    if(_startLocation != null){
      lat = (_startLocation['latitude']).toString();
      lon = (_startLocation['longitude']).toString();
      await this.getCityName(lat, lon);
    }

    final url = "https://api.darksky.net/forecast/"+apiKey+"/"+lat+","+lon+"?units=ca&lang=fr";
    http.Response response = await http.get(Uri.encodeFull(url));

    setState(() {

      this.getCityName(lat, lon);

      if(response.statusCode == 200){
        var jsonData = json.decode(response.body);

        //prévisions actuelle
        cw.temp = ((jsonData['currently']['temperature']).round()).toString();
        cw.cond = jsonData['currently']['summary'];
        cw.uv = (jsonData['currently']['uvIndex']).toString();
        cw.visi = ((jsonData['currently']['visibility']).round()).toString();
        cw.windSpeed = ((jsonData['currently']['windSpeed']).round()).toString();
        cw.windDir = ((jsonData['currently']['windBearing']).round()).toString();
        cw.rainproba = ((jsonData['currently']['precipProbability']).round()).toString();
        cw.tMax = ((jsonData['daily']['data'][0]['temperatureHigh']).round()).toString();
        cw.tMin = ((jsonData['daily']['data'][0]['temperatureLow']).round()).toString();

        //prévisions pour les 6 prochains jours
        for(var i=0; i<5; i++) {
          df[i] = (DailyForecast(
            cond: jsonData['daily']['data'][i+1]['summary'],
            tMax: ((jsonData['daily']['data'][i+1]['temperatureHigh']).round()).toString(),
            tMin: ((jsonData['daily']['data'][i+1]['temperatureLow']).round()).toString(),
            rainProba: (jsonData['daily']['data'][i+1]['precipProbability']).toString(),
            icon: jsonData['daily']['data'][i+1]['icon']
          ));
        }

      }
    });
  }

  //Current Weather Card
  Widget cwCard(){
    return new Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height*0.4,
        // color: Colors.blue[200],
        decoration: new BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: Offset(0.0, 2.0),
              blurRadius: 3.0
            ),
          ]
        ),
        child: new Container(
          color: Colors.blue[200],
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              new Text(cw.temp + "°", style: new TextStyle(color: Colors.white, fontSize: 70.0, fontFamily: 'Raleway', fontWeight: FontWeight.w100)),
              new Divider(height: 15.0, color: Colors.transparent,),
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  new Text(cw.cond+",", style: new TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15.0)),
                  new Text(" "+cityName, style: new TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
                ]
              ),
            ]
          )
        ),
      );
  }

  Widget moreInfoCard(){
    return new Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height*0.1,
      // color: Colors.blue[100],
      decoration: new BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0.0, 2.0),
            blurRadius: 3.0
          ),
        ]
      ),
      child: new Container(
        color: Colors.blue[100],
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [ 
          new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              new Icon(IconData(0xf078, fontFamily: 'weatherIcon'), color: Colors.white, size: 15.0),
              new Divider(height: 5.0),
              new Text(cw.rainproba+" %", style: TextStyle(color: Colors.white)),
            ]
          ),
          new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              new Icon(IconData(0xf050, fontFamily: 'weatherIcon'), color: Colors.white, size: 15.0),
              new Divider(height: 5.0),
              new Text(cw.windSpeed+" km/h", style: TextStyle(color: Colors.white)),
            ]
          ),
          new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              new Icon(IconData(0xf055, fontFamily: 'weatherIcon'), color: Colors.white, size: 15.0),
              new Divider(height: 5.0),
              new Text(cw.tMax+"°", style: TextStyle(color: Colors.white)),
            ]
          ),
          new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              new Icon(IconData(0xf053, fontFamily: 'weatherIcon'), color: Colors.white, size: 15.0),
              new Divider(height: 5.0),
              new Text(cw.tMin+"°", style: TextStyle(color: Colors.white)),
            ]
          )
          ]
        )
      )
    );
  }


  int addWeatherIcon(String iconID){
    if(weatherIcons.containsKey(iconID)){
      return weatherIcons[iconID];
    } else {
      return weatherIcons['default'];
    }
  }

  //Daily Forecast Weather
  Widget dfItem(){

    var date = new TimeToString();
    List <String> days = date.convert();

    return new Expanded(
    child: new ListView.builder(
      itemCount: df.length,
      itemBuilder: (BuildContext context, int i) {
        return new Container(
          decoration: new BoxDecoration(
            border: new Border(bottom: new BorderSide(color: Colors.black.withOpacity(0.1)))
          ),
          child: new ListTile(
          title: new Text(days[i]+" ", 
            style: new TextStyle(color: Colors.blueGrey[550], fontWeight: FontWeight.w500, fontFamily: 'Poppins')
          ),
          subtitle: 
            new Text("Min: " + df[i].tMin + "° Min: "+ df[i].tMax + "°",
              style: new TextStyle(fontWeight: FontWeight.w100, color: Colors.grey[850]),
            ),
          onTap: ()=>print("list taped"+(i).toString()),
          trailing: new Icon(IconData(addWeatherIcon(df[i].icon), fontFamily: 'weatherIcon')),
          contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
            
            
          )
        );
      })
    );
    

  }

  //we build the view using widgets
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text("Parapluie"), centerTitle: true, elevation: 1.8),
      // drawer: new Drawer(),
      body: new Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        cwCard(),
        moreInfoCard(),
        dfItem(),
      ]
      ),
      // floatingActionButton: new FloatingActionButton(child: const Icon(Icons.replay), onPressed: getWeatherData,)
    );
  }

  //here, we define the initial state
  @override
  void initState() {
    super.initState();
    this.getWeatherData();
  }
}
