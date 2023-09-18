// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error AlreadyAMember();

error AlreadyANutrionist();

error InsufficientPayment();

error UnauthorizedApplication(string message);

contract Community {

    uint256 public constant userApplicationFee = 0.01 ether;

    uint256 public constant nutritionistApplicationFee = 0.005 ether;

    address public immutable treasury;

    address[] public allUserAddresses;

    address[] public allNutritionistsAddresses;

    address[] public allNutritionApplicants;

    mapping(address => bool) isMember;

    mapping(address => bool) isNutritionist;

    mapping(address => UserData) public users;

    mapping(address => NutritionistData) public nutritionists;

    mapping(address => NutritionistApplicationStatus) public nutritionistApplicationStatus;

    mapping(address => NutritonistApplication) public nutritionistApplication;

    event NewApplication(address applican, string dataURI);

    enum NutritionistApplicationStatus {
        NotApplied,
        Pending,
        Accepted, 
        Rejected,
        Canceled 
    }

    struct NutritonistApplication {
        string dataURI;
        address nutritionistAddress;
        NutritionistApplicationStatus applicationStatus;
    }

    struct Products {
       string[] meals;
       string[] fitnessPlans;
       string[] consultationServices;
    }

    struct UserData {
        address userAddress;
        string userPersonalData; //needs to be encrypted before storing
        Products purchasedProducts;
    }

    userData[] public allUsers;

    struct NutritionistData {
        string nutritionistPersonalData; //needs to be encrypted before storing
        mapping(address => string) mealPlans;
        address nutritionistAddress;
        mapping(address => string) fitnessPlans;
    }

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function joinCommunity(string _userData) external payable {
        // Check that sender isn't a member already
        if (isMember(msg.sender)) {
            revert AlreadyAMember();
        }

        if (msg.value < userApplicationFee) {
            revert InsufficientPayment();
        }
        isMember(msg.sender) = true;
        UserData storage userData = users[msg.sender];
        userData.userAddress = msg.sender;
        userData.userPersonalData = _userData;

        Products storage products = userData.purchasedProducts;
        products.meals.push("");
        products.meals.push("");
        products.meals.push("");

        allUsers.push(userData);
        allUserAddresses.push(msg.sender);

        payable(treasury).transfer(msg.value);
    }

    /// @notice Function used to apply to community
    function applyForNutritionistRole(string calldata dataURI) external payable {
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[msg.sender];

        // Check that sender isn't a nutritionist already
        if (isNutritionist(msg.sender)) {
            revert AlreadyANutrionist();
        }

        if (applicationStatus == NutritionistApplicationStatus.Pending || applicationStatus == NutritionistApplicationStatus.Accepted) {
            revert UnauthorizedApplication("Community: already applied/pending")
        }
        
        if (msg.value < nutritionistApplicationFee) {
            revert InsufficientPayment();
        }

        nutritionistApplicationStatus = NutritionistApplicationStatus.pending;
        NutritonistApplication memory application = NutritonistApplication(dataURI, msg.sender, nutritionistApplicationStatus);
        nutritionistApplicationStatus[msg.sender] = applicationStatus;
        nutritionistApplication[msg.sender] = application;
        allNutritionApplicants.push(msg.sender);

        payable(treasury).transfer(msg.value);

        // Emit event
        emit NewApplication(msg.sender, dataURI);
    }

    /// @notice Function for community members to approve acceptance of new member to community
    function approveNutritionistRole(address applicant) external onlyOwner {
         NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[msg.sender];
        // Check that applicant isn't a member already
       
        // Check that applicant exists
    

        require(nutritionistApplicationStatus == NutritionistApplicationStatus.pending, "user needs to have a pending application");

        applicationStatus = NutritionistApplicationStatus.accepted;
        nutritionistApplicationStatus[msg.sender] = applicationStatus;
        //nutritionistApplication[]
      

        // Emit event
        emit ApplicatonApproval(msg.sender, applicant);
    }

    function cancelApplication() {

    }
}
