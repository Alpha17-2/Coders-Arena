import 'dart:io';
import 'package:coders_arena/enums/enums.dart';
import 'package:coders_arena/model/user_model.dart';
import 'package:coders_arena/services/api/api_services.dart';
import 'package:coders_arena/services/firebase_services/firebase_storage_services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';


class UserController with ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  ProfileStatus profileStatus = ProfileStatus.nil;
  UserUploadingImage userUploadingImage = UserUploadingImage.notLoading;
  FollowingUserStatus followingUserStatus = FollowingUserStatus.no;
  User? user;

  // set current user
  setUser(String userId) async {
    profileStatus = ProfileStatus.loading;
    final endUrl = 'users/$userId.json';
    try {
      final Response? response = await _apiServices.get(apiEndUrl: endUrl);
      if (response != null) {
        user = User.fromJson(response.data);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    profileStatus = ProfileStatus.fetched;
    notifyListeners();
  }

  // call this method and provide an user object to create a new user
  createUser(User newUser) async {
    try {
      final Response? response = await _apiServices.put(
          apiEndUrl: 'users/${newUser.userId}.json', data: newUser.toJson());
      if (response != null) {
        user = newUser;
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    profileStatus = ProfileStatus.fetched;
    notifyListeners();
  }

  // This method returns an User object.
  Future<User?> getUser(String uid) async {
    try {
      final response = await _apiServices.get(apiEndUrl: 'users/$uid.json');
      if (response != null) {
        return User.fromJson(response.data);
      }
    } catch (error) {
      return null;
    }
    return null;
  }


  // Change display picture , user needs to pass an XFile
  void changeDisplayPhoto(XFile imageFile) async {
    try {
      userUploadingImage = UserUploadingImage.loading;
      await Future.delayed(const Duration(milliseconds: 1));
      notifyListeners();
      String? url = await getImageUrl(
          File(imageFile.path), 'users/${user!.userId}/displayPhoto/dp');
      await _apiServices
          .update(apiEndUrl: 'users/${user!.userId}.json', data: {'dp': url!});
      user!.updateUserDisplayPicture(url);
    } catch (error) {
      return null;
    }
    userUploadingImage = UserUploadingImage.notLoading;
    notifyListeners();
  }

  // By calling this method currently signed in user can follow the user with the passed userd id.
  // void followUser({required userId}) async {
  //   followingUserStatus = FollowingUserStatus.yes;
  //   await Future.delayed(const Duration(milliseconds: 1));
  //   notifyListeners();
  //   try {
  //     User? userToFollow = await getUser(userId); // get user by user id
  //     if (userToFollow != null) {
  //       List<dynamic> followers =
  //           userToFollow.followers; // get their followers.
  //       followers.add(user!.userId); // increase their followers locally.
  //       // update their profile to the server.
  //       await _apiServices.update(
  //           endUrl: 'users/$userId.json', data: {'followers': followers});
  //       // update currently signed in user's profile (increase following list first)
  //       List<dynamic> myFollowings = user!.following;
  //       // increase my following locally.
  //       myFollowings.add(userId);
  //       // update following list to my profile (server)
  //       await _apiServices.update(
  //           endUrl: 'users/${user!.userId}.json',
  //           data: {'following': myFollowings});
  //       user!.following = myFollowings;
  //       notifyUserWhenFollowedUser(user!.userId, userId);
  //     }
  //   } catch (error) {
  //     logger.shout(error.toString());
  //   }
  //   followingUserStatus = FollowingUserStatus.no;
  //   notifyListeners();
  // }
  //
  // // By calling this method currently signed in user can unfollow the user with the passed user id.
  // void unFollowUser({required userId}) async {
  //   Logger logger = Logger("FollowAuthor");
  //   followingUserStatus = FollowingUserStatus.yes;
  //   await Future.delayed(const Duration(milliseconds: 1));
  //   notifyListeners();
  //   try {
  //     User? userToFollow = await getUser(userId); // get user by user id
  //     if (userToFollow != null) {
  //       List<dynamic> followers =
  //           userToFollow.followers; // get their followers.
  //       followers.remove(user!.userId); // increase their followers locally.
  //       // update their profile to the server.
  //       await _apiServices.update(
  //           endUrl: 'users/$userId.json', data: {'followers': followers});
  //       // update currently signed in user's profile (increase following list first)
  //       List<dynamic> myFollowings = user!.following;
  //       // increase my following locally.
  //       myFollowings.remove(userId);
  //       // update following list to my profile (server)
  //       await _apiServices.update(
  //           endUrl: 'users/${user!.userId}.json',
  //           data: {'following': myFollowings});
  //       user!.following = myFollowings;
  //     }
  //   } catch (error) {
  //     logger.shout(error.toString());
  //   }
  //   followingUserStatus = FollowingUserStatus.no;
  //   notifyListeners();
  // }

  // Update profile -> username and bio
  updateProfile({required String name, required String bio}) async {
    try {
      final Response? profileUpdateResponse = await _apiServices
          .update(apiEndUrl: 'users/${user!.userId}.json', data: {
        'name': name,
        'bio': bio,
      });
      if (profileUpdateResponse != null) {
        user!.updateUserProfileData(name, bio);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    notifyListeners();
  }

  // Saves article id and article author id to the list
  // saveArticle({required String authorId, required String articleId}) async {
  //   dynamic savedArticle = {'authorId': authorId, 'articleId': articleId};
  //   List<dynamic> savedArticleList = user!.savedArticles;
  //   savedArticleList.add(savedArticle);
  //   try {
  //     final Response? response = await _apiServices.update(
  //         endUrl: 'users/${user!.userId}.json',
  //         data: {'savedArticles': savedArticleList});
  //     if (response != null) {
  //       user!.updateSavedArticleList(savedArticleList);
  //     }
  //   } catch (error) {
  //     logger.shout(error.toString());
  //   }
  //   notifyListeners();
  // }

  // Unsave the article
  // unSaveArticle({required String authorId, required String articleId}) async {
  //   Logger logger = Logger("unSaveArticle");
  //
  //   List<dynamic> savedArticleList = user!.savedArticles;
  //   int indexTobeRemoved = savedArticleList.indexWhere((element) =>
  //   (element['articleId'] == articleId && element['authorId'] == authorId));
  //
  //   savedArticleList.removeAt(indexTobeRemoved);
  //   try {
  //     final Response? response = await _apiServices.update(
  //         endUrl: 'users/${user!.userId}.json',
  //         data: {'savedArticles': savedArticleList});
  //     if (response != null) {
  //       user!.updateSavedArticleList(savedArticleList);
  //     }
  //   } catch (error) {
  //     logger.shout(error.toString());
  //   }
  //   notifyListeners();
  // }
}