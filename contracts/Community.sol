// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

//import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error AlreadyAMember();

error AlreadyANutrionist();

error InsufficientPayment();

error InvalidApplicant();

error UnauthorizedApplication(string message);

contract Community is Ownable {
    uint256 public constant userApplicationFee = 0.01 ether;

    uint256 public constant nutritionistApplicationFee = 0.005 ether;

    address public immutable treasury;

    address[] public allUserAddresses;

    address[] public allNutritionistsAddresses;

    address[] public allNutritionistsApplicants;

    mapping(address => bool) isMember;

    mapping(address => bool) isNutritionist;

    mapping(address => User) users;

    mapping(address => Nutritionist) public nutritionists;

    mapping(address => NutritionistApplicationStatus)
        public nutritionistApplicationStatus;

    mapping(address => NutritionistApplication) public nutritionistApplications;

    event NewApplication(address applicant, string dataURI);

    event NewSignUp(address user, string dataURI);

    event ApplicationApproved(address applicant);

    enum NutritionistApplicationStatus {
        NotApplied,
        Pending,
        Accepted,
        Rejected,
        Canceled
    }

    enum UserSubscriptionStatus {
        NotActive,
        Active,
        Expired
    }

    struct NutritionistApplication {
        string dataURI;
        address nutritionistAddress;
        NutritionistApplicationStatus applicationStatus;
    }

    NutritionistApplication[] public allNutritionistsApplications;

    struct Products {
        string[] meals;
        string[] fitnessPlans;
        //mapping(address => string) consultationServices;
        string[] consultationServices;
    }

    struct User {
        address userAddress;
        string userPersonalData; //needs to be encrypted before storing
        Products purchasedProducts;
    }

    User[] public allUsers;

    struct Nutritionist {
        string nutritionistPersonalData; //needs to be encrypted before storing
        //mapping(address => string) mealPlans;
        string[] nutritionistMealplans;
        address nutritionistAddress;
        //mapping(address => string) fitnessPlans;
        string[] fitnessPlans;
        string[] consultationServices;
    }

    Nutritionist[] public allNutritionists;

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function joinCommunity(string memory _userData) external payable {
        // Check that sender isn't a member already
        if (isMember[msg.sender]) {
            revert AlreadyAMember();
        }

        if (msg.value < userApplicationFee) {
            revert InsufficientPayment();
        }
        isMember[msg.sender] = true;
        User storage user = users[msg.sender];
        user.userAddress = msg.sender;
        user.userPersonalData = _userData;

        // Products storage products = userData.purchasedProducts;
        // products.meals.push("");
        // products.fitnessPlans.push("");
        // products.meals.push("");

        payable(treasury).transfer(msg.value);
        allUsers.push(user);
        allUserAddresses.push(msg.sender);

        // Emit event
        emit NewSignUp(msg.sender, _userData);
    }

    /// @notice Function used to apply to community
    function applyForNutritionistRole(
        string calldata dataURI
    ) external payable {
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                msg.sender
            ];

        // Check that sender isn't a nutritionist already
        if (isNutritionist[msg.sender]) {
            revert AlreadyANutrionist();
        }

        if (
            applicationStatus == NutritionistApplicationStatus.Pending ||
            applicationStatus == NutritionistApplicationStatus.Accepted
        ) {
            revert UnauthorizedApplication(
                "Community: already applied/pending"
            );
        }

        if (msg.value < nutritionistApplicationFee) {
            revert InsufficientPayment();
        }

        applicationStatus = NutritionistApplicationStatus.Pending;
        NutritionistApplication memory application = NutritionistApplication(
            dataURI,
            msg.sender,
            applicationStatus
        );
        nutritionistApplicationStatus[msg.sender] = applicationStatus;
        nutritionistApplications[msg.sender] = application;
        allNutritionistsApplicants.push(msg.sender);
        allNutritionistsApplications.push(application);

        payable(treasury).transfer(msg.value);

        // Emit event
        emit NewApplication(msg.sender, dataURI);
    }

    /// @notice Function for community members to approve acceptance of new member to community
    function approveNutritionistRole(address applicant) external onlyOwner {
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                applicant
            ];
        // Check that sender isn't a nutritionist already
        if (isNutritionist[applicant]) {
            revert AlreadyANutrionist();
        }

        if (applicationStatus != NutritionistApplicationStatus.Pending) {
            revert InvalidApplicant();
        }

        applicationStatus = NutritionistApplicationStatus.Accepted;
        nutritionistApplicationStatus[applicant] = applicationStatus;

        isNutritionist[applicant] = true;
        NutritionistApplication
            memory _nutritionistApplication = nutritionistApplications[
                applicant
            ];
        Nutritionist memory nutritionist = nutritionists[applicant];
        nutritionist.nutritionistAddress = _nutritionistApplication
            .nutritionistAddress;
        nutritionist.nutritionistPersonalData = _nutritionistApplication
            .dataURI;

        nutritionists[applicant] = nutritionist;
        allNutritionists.push(nutritionist);
        allNutritionistsAddresses.push(applicant);

        // Emit event
        emit ApplicationApproved(applicant);
    }

    // function cancelNutritionistApplication() external onlyNutritionist {}

    // function rejectNutritionistRole() external onlyOwner {}

    // function renewSubscription() external onlyMembers {}

    // function getAllSubscribedMembers() external {}

    // function getAllNutritionists() external {}
}
