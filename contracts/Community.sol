// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

//import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error AlreadyAMember();

error AlreadyANutrionist();

error InsufficientPayment();

error InvalidApplicant();

error UnauthorizedApplication(string message);

error UnauthorizedNutritionist(address caller);

error UnauthorizedMember(address caller);

contract Community is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _indexCounter;

    mapping(address => uint256) public applicantToIndex;

    uint256 public constant userApplicationFee = 0.01 ether;

    uint256 public constant nutritionistApplicationFee = 0.005 ether;

    address public immutable treasury;

    address[] public allUserAddresses;

    address[] public allNutritionistsAddresses;

    address[] public allNutritionistsApplicants; //delete from here

    mapping(address => bool) isMember;

    mapping(address => bool) isNutritionist;

    mapping(address => User) users;

    mapping(address => Nutritionist) public nutritionists;

    mapping(address => NutritionistApplicationStatus) //change to cancelled
        public nutritionistApplicationStatus;

    mapping(address => NutritionistApplication) public nutritionistApplications; //delete from here

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

    // struct Products {
    //     MealPlans[] meals;
    //     FitnessPlans[] fitnessPlans;
    //     ConsultationServices[] consultationServices;
    // }

    struct MealPlans {
        string mealName;
        string mealDescription;
        string creator;
    }

    MealPlans[] public allMealPlans;

    struct FitnessPlans {
        string name;
        string fitnessDescription;
        string creator;
    }

    FitnessPlans[] public allFitnessPlans;

    struct ConsultationServices {
        string consultant;
        string consultationDescription;
    }

    struct User {
        address userAddress;
        string userPersonalData; //needs to be encrypted before storing
        //Products purchasedProducts;
    }

    User[] public allUsers;

    struct Nutritionist {
        string nutritionistPersonalData; //needs to be encrypted before storing
        MealPlans[] nutritionistMealplans;
        address nutritionistAddress;
        FitnessPlans[] fitnessPlans;
        ConsultationServices consultationServices;
    }

    Nutritionist[] public allNutritionists;

    constructor(address _treasury) {
        treasury = _treasury;
    }

    /// @notice Restrict access to trusted `nutritionists`
    modifier onlyNutritionists() {
        if (isNutritionist[msg.sender]) {
            revert UnauthorizedNutritionist(msg.sender);
        }
        _;
    }

    /// @notice Restrict access to trusted `members`
    modifier onlyMembers() {
        if (isMember[msg.sender]) {
            revert UnauthorizedMember(msg.sender);
        }
        _;
    }

    modifier applicantExists(address _applicant) {
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                _applicant
            ];

        if (applicationStatus != NutritionistApplicationStatus.Pending) {
            revert InvalidApplicant();
        }
        _;
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

        // Products storage products = user.purchasedProducts;
        // // Initialize other fields (nested structs) as empty arrays
        // products.meals.push(MealPlans("", "", ""));
        // products.fitnessPlans.push(FitnessPlans("", "", ""));
        // products.consultationServices.push(
        //     ConsultationServices("", "")
        // );

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
        uint256 index = _indexCounter.current();
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
        applicantToIndex[msg.sender] = index;
        nutritionistApplicationStatus[msg.sender] = applicationStatus;
        nutritionistApplications[msg.sender] = application;
        allNutritionistsApplicants.push(msg.sender);
        allNutritionistsApplications.push(application);

        payable(treasury).transfer(msg.value);

        // Emit event
        emit NewApplication(msg.sender, dataURI);
    }

    /// @notice Function for community members to approve acceptance of new member to community
    function approveNutritionistRole(
        address applicant
    ) external onlyOwner applicantExists(applicant) {
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                applicant
            ];
        // Check that sender isn't a nutritionist already
        if (isNutritionist[applicant]) {
            revert AlreadyANutrionist();
        }

        // if (applicationStatus != NutritionistApplicationStatus.Pending) {
        //     revert InvalidApplicant();
        // }

        applicationStatus = NutritionistApplicationStatus.Accepted;
        nutritionistApplicationStatus[applicant] = applicationStatus;

        isNutritionist[applicant] = true;
        NutritionistApplication
            memory _nutritionistApplication = nutritionistApplications[
                applicant
            ];
        Nutritionist storage nutritionist = nutritionists[applicant];
        nutritionist.nutritionistAddress = _nutritionistApplication
            .nutritionistAddress;
        nutritionist.nutritionistPersonalData = _nutritionistApplication
            .dataURI;

        //nutritionists[applicant] = nutritionist;
        allNutritionists.push(nutritionist);
        allNutritionistsAddresses.push(applicant);

        // Emit event
        emit ApplicationApproved(applicant);
    }

    function cancelNutritionistApplication()
        external
        onlyNutritionists
        applicantExists(msg.sender)
    {
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                msg.sender
            ];
        // Check that sender isn't a nutritionist already
        if (isNutritionist[msg.sender]) {
            revert AlreadyANutrionist();
        }

        // if (applicationStatus != NutritionistApplicationStatus.Pending) {
        //     revert InvalidApplicant();
        // }

        uint256 applicantIndex = _getApplicantIndex(msg.sender);
        delete allNutritionistsApplicants[applicantIndex];
        delete nutritionistApplications[msg.sender];

        applicationStatus = NutritionistApplicationStatus.Canceled;
        nutritionistApplicationStatus[msg.sender] = applicationStatus;
    }

    function _getApplicantIndex(
        address _applicant
    ) internal view applicantExists(_applicant) returns (uint256 _index) {
        _index = applicantToIndex[_applicant];
    }

    // function rejectNutritionistRole() external onlyOwner {}

    // function renewSubscription() external onlyMembers {}

    // function getAllSubscribedMembers() external {}

    // function getAllNutritionists() external {}

    // function publishArticle() external {}

    // function createMealPlan() external {}

    // function createFitnessPlan() external {}

    // function createConsultation() external onlyNutritionist {}

    // function calculateRateOfAging() external {}
}
