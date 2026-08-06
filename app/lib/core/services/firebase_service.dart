import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Collection references
  static CollectionReference get members => firestore.collection('members');
  static CollectionReference get clients => firestore.collection('clients');
  static CollectionReference get contractors => firestore.collection('contractors');
  static CollectionReference get administrators => firestore.collection('administrators');
  static CollectionReference get jobs => firestore.collection('jobs');
  static CollectionReference get biddings => firestore.collection('biddings');
  static CollectionReference get transactions => firestore.collection('transactions');
  static CollectionReference get trucks => firestore.collection('trucks');
  static CollectionReference get truckTypes => firestore.collection('truck_types');
  static CollectionReference get truckSchedules => firestore.collection('truck_schedules');
  static CollectionReference get reviews => firestore.collection('reviews');
  static CollectionReference get bankAccounts => firestore.collection('bank_accounts');
  static CollectionReference get locationTracking => firestore.collection('location_tracking');
  static CollectionReference get notifications => firestore.collection('notifications');
}
