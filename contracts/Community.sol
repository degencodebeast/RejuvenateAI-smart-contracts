// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

//import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/automation/interfaces/v1_2/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {KeeperRegistrarInterface} from "./interfaces/KeeperRegistrarInterface.sol";
import {IUserNFT} from "./interfaces/IUserNFT.sol";
import {INutritionistNFT} from "./interfaces/INutritionistNFT.sol";

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
    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;
    //mapping(uint256 => uint256) public counterToUpkeepID;

    using Counters for Counters.Counter;

    Counters.Counter private _applicantIndexCounter;
    Counters.Counter private _userIndexCounter;

    INutritionistNFT public nutritionistNFT;

    IUserNFT public userNFT;

    mapping(address => uint256) public applicantToIndex;

    mapping(address => uint256) public userToIndex;

    uint256 public constant userApplicationFee = 0.01 ether;

    uint256 public constant nutritionistApplicationFee = 0.005 ether;

    uint256 public subscriptionDuration = 2592000;

    address public immutable treasury;

    address[] public allUserAddresses;

    address[] public allNutritionistsAddresses;

    address[] public allNutritionistsApplicants; //delete from here

    mapping(address => bool) isMember;

    mapping(address => bool) isNutritionist;

    mapping(address => User) users; //update users here

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

    User[] public allUsers; //update users here

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

    constructor(
        address _treasury,
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry
        // address _userNFT,
        // address _nutritionistNFT
    ) {
        treasury = _treasury;
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
        // userNFT = IUserNFT(_userNFT);
        // nutritionistNFT = INutritionistNFT(_nutritionistNFT);
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

    function setNFTs(
        address _userNFT,
        address _nutritionistNFT
    ) public onlyOwner {
        userNFT = IUserNFT(_userNFT);
        nutritionistNFT = INutritionistNFT(_nutritionistNFT);
    }

    function joinCommunity(string memory _userData, string memory nftUri) external payable {
        // Check that sender isn't a member already
        if (isMember[msg.sender]) {
            revert AlreadyAMember();
        }

        if (msg.value < userApplicationFee) {
            revert InsufficientPayment();
        }

        uint256 index = _userIndexCounter.current();
        isMember[msg.sender] = true;
        User memory user = users[msg.sender];
        user.userAddress = msg.sender;
        user.userPersonalData = _userData;
        user.subStatus = UserSubscriptionStatus.Active;
        user.subDeadline = block.timestamp + subscriptionDuration;
        users[msg.sender] = user;
        userToIndex[msg.sender] = index;
        allUsers.push(user);
        allUserAddresses.push(msg.sender);

        //mint userNft for the user
        userNFT.mint(msg.sender, nftUri);
        payable(treasury).transfer(msg.value);

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
        if (block.timestamp > user.subDeadline) {
            user.subStatus = UserSubscriptionStatus.Expired;
            user.subDeadline = 0;
        }
        users[_member] = user;
        uint256 userIndex = _getUserIndex(_member);
        allUsers[userIndex] = user;
        uint256 userTokenId = userNFT.getTokenIdOfOwner(user.userAddress);

        userNFT.burn(user.userAddress, userTokenId);
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

        uint256 index = _applicantIndexCounter.current();
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

    function _getUserIndex(
        address _user
    ) internal view returns (uint256 _index) {
        if (!isMember[_user]) {
            revert UnauthorizedMember(_user);
        }
        _index = userToIndex[_user];
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

    function registerAndPredictID(
        string memory name, //upkeep name
        bytes calldata encryptedEmail, // '0x'
        address upkeepContract, //address(this)
        uint32 gasLimit, //500000
        address adminAddress, //address(msg.sender)
        bytes calldata checkData, //0x - ABI-encoded, it is fixed and specified at Upkeep registration and used in every checkUpkeep. Can be empty (0x)
        uint96 amount, //5 link - 5000000000000000000 wei
        uint8 source //0
    ) public {
        (State memory state, , ) = i_registry.getState();
        uint256 oldNonce = state.nonce; //number representing current upkeep
        bytes memory payload = abi.encode(
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            amount,
            source,
            address(this)
        );
        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, , ) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            // DEV - Use the upkeepID however you see fit
            //counterToUpkeepID[counterID] = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        //decode check data if you using it
        //if interval has passed then return true

        bool status;
        User[] memory newUserArr = new User[](allUsers.length);
        for (uint16 i = 0; i < allUsers.length; i++) {
            User memory user = allUsers[i];
            if (block.timestamp > user.subDeadline) {
                // user.subStatus = UserSubscriptionStatus.Expired;
                // user.subDeadline = 0;
                newUserArr[i] = user;
                status = true;
            }
        }
        //upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        upkeepNeeded = status;
        performData = abi.encode(newUserArr);
        //pass checkData through to performData
    }

    function performUpkeep(bytes calldata performData) external {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        User[] memory usersArr = abi.decode(performData, (User[]));
        for (uint16 i = 0; i < usersArr.length; i++) {
            User memory user = usersArr[i];
            address userAddress = user.userAddress;
            if (block.timestamp > user.subDeadline) {
                revokeUser(userAddress);
            }
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }
}
