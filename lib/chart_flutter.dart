import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert';

// Diambil dari: https://blog.logrocket.com/how-create-flutter-charts-with-charts-flutter/

class PopulasiTahun {
  String tahun; // Perlu string
  int populasi;
  charts.Color barColor;

  PopulasiTahun({
    required this.tahun,
    required this.populasi,
    required this.barColor,
  });
}

class Populasi {
  List<PopulasiTahun> listPop = <PopulasiTahun>[];

  Populasi(Map<String, dynamic> json) {
    // Isi listPop disini
    var data = json["data"];
    for (var val in data) {
      var tahun = val["Year"].toString(); // Konversi ke string
      var populasi = val["Population"];
      var warna =
          charts.ColorUtil.fromDartColor(Colors.green); // Satu warna dulu
      listPop.add(PopulasiTahun(
        tahun: tahun,
        populasi: populasi,
        barColor: warna,
      ));
    }
  }

  // Map dari json ke atribut
  factory Populasi.fromJson(Map<String, dynamic> json) {
    return Populasi(json);
  }
}

class PopulasiChart extends StatelessWidget {
  final List<PopulasiTahun> listPop;

  PopulasiChart({required this.listPop});

  @override
  Widget build(BuildContext context) {
    List<charts.Series<PopulasiTahun, String>> series = [
      charts.Series(
        id: "populasi",
        data: listPop,
        domainFn: (PopulasiTahun series, _) => series.tahun,
        measureFn: (PopulasiTahun series, _) => series.populasi,
        colorFn: (PopulasiTahun series, _) => series.barColor,
      )
    ];
    return charts.BarChart(series, animate: true);
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chart-Http",
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

// Class state
class HomePageState extends State<HomePage> {
  late Future<Populasi> futurePopulasi;

  // https://datausa.io/api/data?drilldowns=Nation&measures=Population
  String url =
      "https://datausa.io/api/data?drilldowns=Nation&measures=Population";

  // Fetch data
  Future<Populasi> fetchData() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Jika server mengembalikan 200 OK (berhasil),
      // parse json
      return Populasi.fromJson(jsonDecode(response.body));
    } else {
      // Jika gagal (bukan  200 OK),
      // lempar exception
      throw Exception('Gagal load');
    }
  }

  @override
  void initState() {
    super.initState();
    futurePopulasi = fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart - HTTP'),
      ),
      body: FutureBuilder<Populasi>(
        future: futurePopulasi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Jika masih dalam proses loading
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // Jika data sudah diterima
            return Center(
                child: PopulasiChart(listPop: snapshot.data!.listPop));
          } else if (snapshot.hasError) {
            // Jika terjadi error
            return Center(child: Text('${snapshot.error}'));
          } else {
            // Kasus lainnya
            return Center(child: Text('Data tidak tersedia'));
          }
        },
      ),
    );
  }
}
