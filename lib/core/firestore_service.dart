import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/subscription.dart';
import '../models/job_post.dart';
import 'auth_service.dart';

/// Firestore service for cloud data storage
/// Replaces FileStore with cloud-based storage
class FirestoreService {
  static final FirestoreService I = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection names
  static const String _expensesCollection = 'expenses';
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _jobsCollection = 'jobs';
  static const String _budgetCollection = 'budget';
  static const String _usersCollection = 'users';

  // Get current user ID from AuthService
  String get _userId => AuthService.I.currentUserId ?? 'anonymous';

  // ==================== User Role ====================

  /// Check if current user is admin
  Future<bool> isUserAdmin() async {
    try {
      final doc = await _db.collection(_usersCollection).doc(_userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // ==================== Expenses ====================

  /// Get all expenses for current user
  Future<List<Expense>> getExpenses() async {
    try {
      final snapshot = await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_expensesCollection)
          .orderBy('spend_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error loading expenses: $e');
      return [];
    }
  }

  /// Add a new expense
  Future<void> addExpense(Expense expense) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_expensesCollection)
          .doc(expense.id)
          .set(expense.toJson());
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_expensesCollection)
          .doc(expenseId)
          .delete();
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  /// Listen to expenses changes in real-time
  Stream<List<Expense>> watchExpenses() {
    return _db
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_expensesCollection)
        .orderBy('spend_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ==================== Subscriptions ====================

  /// Get all subscriptions for current user
  Future<List<Subscription>> getSubscriptions() async {
    try {
      final snapshot = await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_subscriptionsCollection)
          .get();

      return snapshot.docs
          .map((doc) => Subscription.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error loading subscriptions: $e');
      return [];
    }
  }

  /// Add a new subscription
  Future<void> addSubscription(Subscription subscription) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_subscriptionsCollection)
          .doc(subscription.id)
          .set(subscription.toJson());
    } catch (e) {
      print('Error adding subscription: $e');
      rethrow;
    }
  }

  /// Update a subscription
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_subscriptionsCollection)
          .doc(subscription.id)
          .update(subscription.toJson());
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  /// Delete a subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_subscriptionsCollection)
          .doc(subscriptionId)
          .delete();
    } catch (e) {
      print('Error deleting subscription: $e');
      rethrow;
    }
  }

  /// Listen to subscriptions changes in real-time
  Stream<List<Subscription>> watchSubscriptions() {
    return _db
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_subscriptionsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subscription.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ==================== Jobs ====================

  /// Get all job posts
  Future<List<JobPost>> getJobs() async {
    try {
      final snapshot = await _db
          .collection(_jobsCollection)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => JobPost.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error loading jobs: $e');
      return [];
    }
  }

  /// Add a new job post
  Future<void> addJob(JobPost job) async {
    try {
      await _db.collection(_jobsCollection).doc(job.id).set(job.toJson());
    } catch (e) {
      print('Error adding job: $e');
      rethrow;
    }
  }

  /// Delete a job post
  Future<void> deleteJob(String jobId) async {
    try {
      await _db.collection(_jobsCollection).doc(jobId).delete();
    } catch (e) {
      print('Error deleting job: $e');
      rethrow;
    }
  }

  /// Listen to jobs changes in real-time
  Stream<List<JobPost>> watchJobs() {
    return _db
        .collection(_jobsCollection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobPost.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // ==================== Budget ====================

  /// Get budget settings
  Future<Map<String, dynamic>> getBudget() async {
    try {
      final doc = await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_budgetCollection)
          .doc('settings')
          .get();

      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error loading budget: $e');
      return {};
    }
  }

  /// Save budget settings
  Future<void> saveBudget(Map<String, dynamic> budgetData) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection(_budgetCollection)
          .doc('settings')
          .set(budgetData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving budget: $e');
      rethrow;
    }
  }

  /// Listen to budget changes in real-time
  Stream<Map<String, dynamic>> watchBudget() {
    return _db
        .collection(_usersCollection)
        .doc(_userId)
        .collection(_budgetCollection)
        .doc('settings')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  // ==================== Subscription Alerts ====================

  /// Get sent subscription alerts
  Future<Set<String>> getSentSubscriptionAlerts() async {
    try {
      final doc = await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection('alerts')
          .doc('subscription_alerts')
          .get();

      if (doc.exists && doc.data()?['sent_alerts'] != null) {
        return Set<String>.from(doc.data()!['sent_alerts'] as List);
      }
      return {};
    } catch (e) {
      print('Error loading subscription alerts: $e');
      return {};
    }
  }

  /// Save sent subscription alerts
  Future<void> saveSentSubscriptionAlerts(Set<String> alerts) async {
    try {
      await _db
          .collection(_usersCollection)
          .doc(_userId)
          .collection('alerts')
          .doc('subscription_alerts')
          .set({'sent_alerts': alerts.toList()});
    } catch (e) {
      print('Error saving subscription alerts: $e');
    }
  }
}

