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

error InvalidDeadline();

error InvalidSubStatus();

contract Community is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _indexCounter;

    mapping(address => uint256) public applicantToIndex;

    uint256 public constant userApplicationFee = 0.01 ether;

    uint256 public constant nutritionistApplicationFee = 0.005 ether;

    uint256 public subscriptionDuration = 2592000;

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
        address creator;
    }

    MealPlans[] public allMealPlans;

    struct FitnessPlans {
        string name;
        string fitnessDescription;
        address creator;
    }

    FitnessPlans[] public allFitnessPlans;

    struct ConsultationServices {
        address consultant;
        string consultationDescription;
    }

    struct User {
        address userAddress;
        string userPersonalData; //needs to be encrypted before storing
        //Products purchasedProducts;
        UserSubscriptionStatus subStatus;
        uint256 subDeadline;
    }

    User[] public allUsers;

    struct Nutritionist {
        //string name;
        string nutritionistPersonalData; //needs to be encrypted before storing
        MealPlans[] nutritionistMealplans;
        address nutritionistAddress;
        FitnessPlans[] fitnessPlans;
        ConsultationServices consultationServices;
        Articles[] nutritionistArticles;
    }

    Nutritionist[] public allNutritionists;

    struct Articles {
        string title;
        address author;
        string authorName;
        string content;
    }

    Articles[] public allArticles;

    constructor(address _treasury) {
        treasury = _treasury;
    }

    /// @notice Restrict access to trusted `nutritionists`
    modifier onlyNutritionists() {
        if (!isNutritionist[msg.sender]) {
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

    modifier deadlinePassed(address _member) {
        uint256 deadline = users[_member].subDeadline;

        if (block.timestamp < deadline) {
            revert InvalidDeadline();
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
        User memory user = users[msg.sender];
        user.userAddress = msg.sender;
        user.userPersonalData = _userData;
        user.subStatus = UserSubscriptionStatus.Active;
        user.subDeadline = block.timestamp + subscriptionDuration;

        users[msg.sender] = user;
        //mint userNft for the user

        payable(treasury).transfer(msg.value);
        allUsers.push(user);
        allUserAddresses.push(msg.sender);

        // Emit event
        emit NewSignUp(msg.sender, _userData);
    }

    //should be called by automation
    function revokeUser(
        address _member
    ) public /*onlyChainlink*/ deadlinePassed(_member) {
        // This function can only be called by the owner after the deadline has passed

        if (!isMember[_member]) {
            revert UnauthorizedMember(_member);
        }

        User memory user = users[_member];
        //isMember[_member] = false;
        user.subStatus = UserSubscriptionStatus.Expired;
        users[_member] = user;

        //TODO
        //burn user nft with automation
        //nft will be used for access control with lighthouse
    }

    /// @notice Function used to apply to community
    function applyForNutritionistRole(
        string calldata dataURI
    ) external payable {
        // Check that sender isn't a nutritionist already
        if (isNutritionist[msg.sender]) {
            revert AlreadyANutrionist();
        }

        uint256 index = _indexCounter.current();
        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                msg.sender
            ];

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

    function cancelNutritionistApplication()
        external
        onlyNutritionists
        applicantExists(msg.sender)
    {
        // Check that sender isn't a nutritionist already
        if (isNutritionist[msg.sender]) {
            revert AlreadyANutrionist();
        }

        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                msg.sender
            ];

        // if (applicationStatus != NutritionistApplicationStatus.Pending) {
        //     revert InvalidApplicant();
        // }

        uint256 applicantIndex = _getApplicantIndex(msg.sender);
        delete allNutritionistsApplicants[applicantIndex];
        delete nutritionistApplications[msg.sender];

        applicationStatus = NutritionistApplicationStatus.Canceled;
        nutritionistApplicationStatus[msg.sender] = applicationStatus;
    }

    /// @notice Function for community members to approve acceptance of new member to community
    function approveNutritionistRole(
        address applicant
    ) external onlyOwner applicantExists(applicant) {
        // Check that sender isn't a nutritionist already
        if (isNutritionist[applicant]) {
            revert AlreadyANutrionist();
        }

        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                applicant
            ];

        // if (applicationStatus != NutritionistApplicationStatus.Pending) {
        //     revert InvalidApplicant();
        // }

        applicationStatus = NutritionistApplicationStatus.Accepted;
        nutritionistApplicationStatus[applicant] = applicationStatus;

        //TODO
        //mint nutritionist nft for nutritionist

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

        allNutritionists.push(nutritionist);
        allNutritionistsAddresses.push(applicant);

        // Emit event
        emit ApplicationApproved(applicant);
    }

    function _getApplicantIndex(
        address _applicant
    ) internal view applicantExists(_applicant) returns (uint256 _index) {
        _index = applicantToIndex[_applicant];
    }

    function rejectNutritionistRole(
        address applicant
    ) external onlyOwner applicantExists(applicant) {
        // Check that sender isn't a nutritionist already
        if (isNutritionist[applicant]) {
            revert AlreadyANutrionist();
        }

        NutritionistApplicationStatus applicationStatus = nutritionistApplicationStatus[
                applicant
            ];

        applicationStatus = NutritionistApplicationStatus.Rejected;
        nutritionistApplicationStatus[applicant] = applicationStatus;
    }

    function renewSubscription()
        external
        onlyMembers
        deadlinePassed(msg.sender)
    {
        User memory user = users[msg.sender];
        if (user.subStatus != UserSubscriptionStatus.Expired) {
            revert InvalidSubStatus();
        }
        user.subStatus = UserSubscriptionStatus.Active;
        //isMember[msg.sender] = true;
        users[msg.sender] = user;

        //TODO
        //mint user nft
    }

    function getAllMembers() external view returns (User[] memory _users) {
        _users = allUsers;
    }

    function getAllNutritionists()
        external
        view
        returns (Nutritionist[] memory _nutritionists)
    {
        _nutritionists = allNutritionists;
    }

    function createMealPlan(
        string memory _mealName,
        string memory mealPlanDesc
    ) external onlyNutritionists {
        Nutritionist storage _nutritionist = nutritionists[msg.sender];
        MealPlans memory mealPlan = MealPlans(
            _mealName,
            mealPlanDesc,
            msg.sender
        );
        _nutritionist.nutritionistMealplans.push(mealPlan);
    }

    function createFitnessPlan(
        string memory _fitnessName,
        string memory fitnessDesc
    ) external onlyNutritionists {
        Nutritionist storage _nutritionist = nutritionists[msg.sender];
        FitnessPlans memory fitnessPlan = FitnessPlans(
            _fitnessName,
            fitnessDesc,
            msg.sender
        );
        _nutritionist.fitnessPlans.push(fitnessPlan);
    }

    function createConsultation(
        string memory _consultationDesc
    ) external onlyNutritionists {
        Nutritionist storage _nutritionist = nutritionists[msg.sender];
        ConsultationServices memory consultationService = ConsultationServices(
            msg.sender,
            _consultationDesc
        );
        _nutritionist.consultationServices = consultationService;
    }

    function publishArticle(
        string memory _title,
        string memory _authorName,
        string memory _content
    ) external onlyOwner onlyNutritionists {
        Nutritionist storage _nutritionist = nutritionists[msg.sender];
        Articles memory article = Articles(
            _title,
            msg.sender,
            _authorName,
            _content
        );
        _nutritionist.nutritionistArticles.push(article);
        allArticles.push(article);
    }

    // function calculateRateOfAging() external {}
}
