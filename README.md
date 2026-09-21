# Jose Neil Silagan Jr.
## INF231MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics. Covering the Mobile to Web transactions.

## Lab Activity Instance
- Lab Activity 1: In saving a value in the flutter project, there are two ways, the setState and the provider. In the setState, it manages local widget state. Meaning, it doesn’t save the value when navigating to different pages and popped, ideal for temporary data. While provider is global, meaning, it remembers the value all across the project. So whenever you navigate to different pages, it remembers the value. Similar to the dark and light mode, it remembers if the next page is dark or light.

- Lab Activity 2: Model, service, and screens works synchronously from fetching to rendering the values on the frontend. Model serves as the one that tells the form of what the data that will be received by the frontend. The service is the one that fetches the values from a server or a backend. The function in the service is then used in the screens to be rendered for users to see.

- Lab Activity 3: In this activity, we implemented the carl model as the structure or the form of the data that we will use. The cart_service is the one that contains all the service calls on the dummyjson link to fetch the data, and the screen is the one the is used by the user to view the items in the cart.  We also updated the home_screen to use the floating action button for the messages to toggle on and off when navigating to other pages disappearing in the carts. We used getById to fetch the specific carts for a user ID.

- Lab Activity 4: The user model is the shape that will be followed when the data is fetched, service is the one that post and fetches the users from the server of dummyjson, while the screen is the platform that the users use. From the login, the data is posted to the server of dummyjson, and then saved in the shared preferences. Its now different from the previous activities where the cart is referenced using a hardcoded id, while in the activity 4 it uses the user id of the fetched user. 

- Lab Activity 5: From the previous activity, we only implemented the mock api calls through dummyJSON, which is a backend intended for learning only. It doesn’t have a signup and the signin is static that came from the dummyJSON itself. By implementing the firebase, we created a authentication utilizing the firebase tool from sign up to sign in. With the userService implementation, we created a basic CRUD functionality for the user. By using firebase, we are utilizing the modernize cloud implementation highlighting the authentication of firebase.