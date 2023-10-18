// ignore_for_file: avoid_print

import 'package:canteen_food_ordering_app_v3/models/food.dart';
import 'package:canteen_food_ordering_app_v3/models/user.dart' as MyAppUser;
import 'package:canteen_food_ordering_app_v3/notifiers/authNotifier.dart';
import 'package:canteen_food_ordering_app_v3/screens/adminHome.dart';
import 'package:canteen_food_ordering_app_v3/screens/login.dart';
import 'package:canteen_food_ordering_app_v3/screens/navigationBar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

late ProgressDialog pr;

void toast(String data) {
  Fluttertoast.showToast(
      msg: data,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey,
      textColor: Colors.white);
}

login(MyAppUser.User user, AuthNotifier authNotifier,
    BuildContext context) async {
  late ProgressDialog pr = ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  UserCredential authResult;
  try {
    authResult = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: user.email, password: user.password);
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }

  try {
    User? firebaseUser = authResult.user;
    if (!firebaseUser!.emailVerified) {
      await FirebaseAuth.instance.signOut();
      pr.hide().then((isHidden) {
        print(isHidden);
      });
      toast("Email ID not verified");
      return;
    } else {
      print("Log In: $firebaseUser");
    }
    authNotifier.setUser(firebaseUser);
    await getUserDetails(authNotifier);
    print("done");
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    if (authNotifier.userDetails?.role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) {
          return const AdminHomePage();
        }),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) {
          return NavigationBarPage(selectedIndex: 1);
        }),
      );
    }
    } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }
}

signUp(MyAppUser.User user, AuthNotifier authNotifier,
    BuildContext context) async {
  pr =  ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  bool userDataUploaded = false;
  UserCredential authResult;
  try {
    authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email.trim(), password: user.password);
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }

  try {
    if (authResult != null) {
      await FirebaseAuth.instance.currentUser?.updateProfile(displayName:user.displayName);

      User? firebaseUser = authResult.user;
      await firebaseUser?.sendEmailVerification();

      if (firebaseUser != null) {
        await firebaseUser.updateProfile(displayName: user.displayName);
        await firebaseUser.reload();
        print("Sign Up: $firebaseUser");
        uploadUserData(user, userDataUploaded);
        await FirebaseAuth.instance.signOut();
        authNotifier.setUser(null);
        pr.hide().then((isHidden) {
          print(isHidden);
        });
        toast("Verification link is sent to ${user.email}");
        Navigator.pop(context);
      }
    }
    pr.hide().then((isHidden) {
      print(isHidden);
    });
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }
}

getUserDetails(AuthNotifier authNotifier) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(authNotifier.user?.uid)
      .get()
      .catchError((e) => print(e))
      .then((value) => {
            (value != null)
                ? authNotifier
                    .setUserDetails(MyAppUser.User.fromMap(value.data as Map<String, dynamic>))
                : print(value)
          });
}

uploadUserData(MyAppUser.User user, bool userdataUpload) async {
  bool userDataUploadVar = userdataUpload;
  User? currentUser = await FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    CollectionReference userRef = FirebaseFirestore.instance.collection('users');
    CollectionReference cartRef = FirebaseFirestore.instance.collection('carts');

    user.uuid = currentUser.uid;
    if (userDataUploadVar != true) {
      await userRef
          .doc(currentUser.uid)
          .set(user.toMap())
          .catchError((e) => print(e))
          .then((value) => userDataUploadVar = true);
      await cartRef
          .doc(currentUser.uid)
          .set({})
          .catchError((e) => print(e))
          .then((value) => userDataUploadVar = true);
    } else {
      print('already uploaded user data');
    }
    print('user data uploaded successfully');
  }
  
}

initializeCurrentUser(AuthNotifier authNotifier, BuildContext context) async {
  User? firebaseUser = await FirebaseAuth.instance.currentUser;
  authNotifier.setUser(firebaseUser);
  await getUserDetails(authNotifier);
}

signOut(AuthNotifier authNotifier, BuildContext context) async {
  await FirebaseAuth.instance.signOut();

  authNotifier.setUser(null);
  print('log out');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (BuildContext context) {
      return const LoginPage();
    }),
  );
}

forgotPassword(MyAppUser.User user, AuthNotifier authNotifier,
    BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast(error.toString());
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Reset Email has sent successfully");
  Navigator.pop(context);
}

addToCart(Food food, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    User? currentUser = await FirebaseAuth.instance.currentUser;
    CollectionReference cartRef = FirebaseFirestore.instance.collection('carts');
    QuerySnapshot data = await cartRef
        .doc(currentUser?.uid)
        .collection('items')
        .get();
    if (data.docs.length >= 10) {
      pr.hide().then((isHidden) {
        print(isHidden);
      });
      toast("Cart cannot have more than 10 times!");
      return;
    }
    await cartRef
        .doc(currentUser?.uid)
        .collection('items')
        .doc(food.id)
        .set({"count": 1})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to add to cart!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Added to cart successfully!");
}

removeFromCart(Food food, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    User? currentUser = await FirebaseAuth.instance.currentUser;
    CollectionReference cartRef = FirebaseFirestore.instance.collection('carts');
    await cartRef
        .doc(currentUser?.uid)
        .collection('items')
        .doc(food.id)
        .delete()
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to Remove from cart!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Removed from cart successfully!");
}

addNewItem(
    String itemName, int price, int totalQty, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference itemRef = FirebaseFirestore.instance.collection('items');
    await itemRef
        .doc()
        .set({"item_name": itemName, "price": price, "total_qty": totalQty})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to add to new item!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("New Item added successfully!");
}

editItem(String itemName, int price, int totalQty, BuildContext context,
    String id) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference itemRef = FirebaseFirestore.instance.collection('items');
    await itemRef
        .doc(id)
        .set({"item_name": itemName, "price": price, "total_qty": totalQty})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to edit item!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("Item edited successfully!");
}

deleteItem(String id, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference itemRef = FirebaseFirestore.instance.collection('items');
    await itemRef
        .doc(id)
        .delete()
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to edit item!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("Item edited successfully!");
}

editCartItem(String itemId, int count, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    User? currentUser = await FirebaseAuth.instance.currentUser;
    CollectionReference cartRef = FirebaseFirestore.instance.collection('carts');
    if (count <= 0) {
      await cartRef
          .doc(currentUser?.uid)
          .collection('items')
          .doc(itemId)
          .delete()
          .catchError((e) => print(e))
          .then((value) => print("Success"));
    } else {
      await cartRef
          .doc(currentUser?.uid)
          .collection('items')
          .doc(itemId)
          .update({"count": count})
          .catchError((e) => print(e))
          .then((value) => print("Success"));
    }
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to update Cart!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  toast("Cart updated successfully!");
}

addMoney(int amount, BuildContext context, String? id) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference userRef = FirebaseFirestore.instance.collection('users');
    await userRef
        .doc(id)
        .update({'balance': FieldValue.increment(amount)})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to add money!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (BuildContext context) {
      return NavigationBarPage(selectedIndex: 1);
    }),
  );
  toast("Money added successfully!");
}

placeOrder(BuildContext context, double total) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    // Initiaization
    User? currentUser = await FirebaseAuth.instance.currentUser;
    CollectionReference cartRef = FirebaseFirestore.instance.collection('carts');
    CollectionReference orderRef = FirebaseFirestore.instance.collection('orders');
    CollectionReference itemRef = FirebaseFirestore.instance.collection('items');
    CollectionReference userRef = FirebaseFirestore.instance.collection('users');

    List<String> foodIds = List.empty();
    Map<String, int> count = new Map<String, int>();
    List<dynamic> _cartItems = List.empty();

    // Checking user balance
    DocumentSnapshot userData = await userRef.doc(currentUser?.uid).get();
    if (userData['balance'] < total) {
      pr.hide().then((isHidden) {
        print(isHidden);
      });
      toast("You dont have succifient balance to place this order!");
      return;
    }

    // Getting all cart items of the user
    QuerySnapshot data = await cartRef
        .doc(currentUser?.uid)
        .collection('items')
        .get();
    data.docs.forEach((item) {
      foodIds.add(item.id);
      count[item.id] = item['count'];
    });

    // Checking for item availability
    QuerySnapshot snap = await itemRef
        .where(FieldPath.documentId, whereIn: foodIds)
        .get();
    for (var i = 0; i < snap.docs.length; i++) {
      if (snap.docs[i]['total_qty'] <
          count[snap.docs[i].id]) {
        pr.hide().then((isHidden) {
          print(isHidden);
        });
        print("not");
        toast(
            "Item: ${snap.docs[i]['item_name']} has QTY: ${snap.docs[i]['total_qty']} only. Reduce/Remove the item.");
        return;
      }
    }

    // Creating cart items array
    snap.docs.forEach((item) {
      _cartItems.add({
        "item_id": item.id,
        "count": count[item.id],
        "item_name": item['item_name'],
        "price": item['price']
      });
    });

    // Creating a transaction
    await FirebaseFirestore.instance.runTransaction((Transaction transaction) async {
      // Update the item count in items table
      for (var i = 0; i < snap.docs.length; i++) {
        await transaction.update(snap.docs[i].reference, {
          "total_qty": snap.docs[i]["total_qty"] -
              count[snap.docs[i].id]
        });
      }

      // Deduct amount from user
      await userRef
          .doc(currentUser?.uid)
          .update({'balance': FieldValue.increment(-1 * total)});

      // Place a new order
      await orderRef.doc().set({
        "items": _cartItems,
        "is_delivered": false,
        "total": total,
        "placed_at": DateTime.now(),
        "placed_by": currentUser?.uid
      });

      // Empty cart
      for (var i = 0; i < data.docs.length; i++) {
        await transaction.delete(data.docs[i].reference);
      }
      print("in in");
      // return;
    });

    // Successfull transaction
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) {
        return NavigationBarPage(selectedIndex: 1);
      }),
    );
    toast("Order Placed Successfully!");
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    Navigator.pop(context);
    toast("Failed to place order!");
    print(error);
    return;
  }
}

orderReceived(String id, BuildContext context) async {
  pr = new ProgressDialog(context,
      type: ProgressDialogType.normal, isDismissible: false, showLogs: false);
  pr.show();
  try {
    CollectionReference ordersRef = FirebaseFirestore.instance.collection('orders');
    await ordersRef
        .doc(id)
        .update({'is_delivered': true})
        .catchError((e) => print(e))
        .then((value) => print("Success"));
  } catch (error) {
    pr.hide().then((isHidden) {
      print(isHidden);
    });
    toast("Failed to mark as received!");
    print(error);
    return;
  }
  pr.hide().then((isHidden) {
    print(isHidden);
  });
  Navigator.pop(context);
  toast("Order received successfully!");
}
