// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './abstracts/AccessControl.sol';
import './interfaces/IERC721Receiver.sol';
import './libraries/Counters.sol';
import './libraries/SafeBEP20.sol';
import './interfaces/IRandom.sol';
import './interfaces/IERC721.sol';

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


contract BonkeyProfile is AccessControl, ERC721Holder {
    using Counters for Counters.Counter;
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    IBEP20 public bnkyToken;
    IRandom private randNumber;

    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");
    bytes32 public constant POINT_ROLE = keccak256("POINT_ROLE");
    bytes32 public constant SPECIAL_ROLE = keccak256("SPECIAL_ROLE");

    uint256 public numberActiveProfiles;
    uint256 public numberBnkyToReactivate;
    uint256 public numberBnkyToRegister;
    uint256 public numberBnkyToUpdate;
    uint256 public numberTeams;

    mapping(address => bool) public hasRegistered;

    mapping(uint256 => Team) private teams;
    mapping(address => User) private users;
    uint256 base = 10000;
    uint256[] public prizes;
    uint256   public numPrizes;

    // Used for generating the teamId
    Counters.Counter private _countTeams;

    // Used for generating the userId
    Counters.Counter private _countUsers;

    // Event to notify a new team is created
    event TeamAdd(uint256 teamId, string teamName);

    // Event to notify that team points are increased
    event TeamPointIncrease(
        uint256 indexed teamId,
        uint256 numberPoints,
        uint256 indexed campaignId
    );

    event UserChangeTeam(
        address indexed userAddress,
        uint256 oldTeamId,
        uint256 newTeamId
    );

    // Event to notify that a user is registered
    event UserNew(
        address indexed userAddress,
        uint256 teamId,
        address nftAddress,
        uint256 tokenId
    );

    // Event to notify a user pausing her profile
    event UserPause(address indexed userAddress, uint256 teamId);

    // Event to notify that user points are increased
    event UserPointIncrease(
        address indexed userAddress,
        uint256 numberPoints,
        uint256 indexed campaignId
    );

    // Event to notify that a list of users have an increase in points
    event UserPointIncreaseMultiple(
        address[] userAddresses,
        uint256 numberPoints,
        uint256 indexed campaignId
    );

    // Event to notify that a user is reactivating her profile
    event UserReactivate(
        address indexed userAddress,
        uint256 teamId,
        address nftAddress,
        uint256 tokenId
    );

    // Event to notify that a user is pausing her profile
    event UserUpdate(
        address indexed userAddress,
        address nftAddress,
        uint256 tokenId
    );

    // Modifier for admin roles
    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Not the main admin"
        );
        _;
    }

    // Modifier for point roles
    modifier onlyPoint() {
        require(hasRole(POINT_ROLE, _msgSender()), "Not a point admin");
        _;
    }

    // Modifier for special roles
    modifier onlySpecial() {
        require(hasRole(SPECIAL_ROLE, _msgSender()), "Not a special admin");
        _;
    }

    struct Team {
        string teamName;
        string teamDescription;
        uint256 numberUsers;
        uint256 numberPoints;
        bool isJoinable;
    }

    struct User {
        uint256 userId;
        uint256 numberPoints;
        uint256 teamId;
        address nftAddress;
        uint256 tokenId;
        bool isActive;
    }

    function initialize (
    ) public initializer {
        bnkyToken = IBEP20(0xAdc8e9B18b671DF686acCe0543F086293f2ef886);
        numberBnkyToReactivate = 100000000000000000000;
        numberBnkyToRegister = 100000000000000000000;
        numberBnkyToUpdate = 100000000000000000000;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        randNumber = IRandom(0xA280f520AeFBb1390182c00Ca9B718a4B68eAd4D);
    }
    
    function set_prize(uint256[] calldata _prizes) external onlyOwner {
        if(numPrizes == 5) {
            prizes[0] = _prizes[0];
            prizes[1] = _prizes[1];
            prizes[2] = _prizes[2];
            prizes[3] = _prizes[3];
            prizes[4] = _prizes[4];
        } else {
            prizes.push(_prizes[0]);
            prizes.push(_prizes[1]);
            prizes.push(_prizes[2]);
            prizes.push(_prizes[3]);
            prizes.push(_prizes[4]);
            numPrizes = 5;
        }
    }
    
    function determine_prize(address sender) internal returns (uint256) {
        uint256 randNum = randNumber.generate_random(base, sender); 
        uint256 ret = 0;
        if(randNum.mod(10000) == 0) {
            ret = prizes[0].mul(1e18);
        } else if(randNum.mod(1000) == 0) {
            ret = prizes[1].mul(1e18);
        } else if(randNum.mod(100) == 0) {
            ret = prizes[2].mul(1e18);
        } else if(randNum.mod(10) == 0) {
            ret = prizes[3].mul(1e18);
        } else {
            ret = prizes[4].mul(1e18);
        }
        return ret;
    }

    /**
     * @dev To create a user profile. It sends the NFT to the contract
     * and sends BNKY to burn address. Requires 2 token approvals.
     */
    function createProfile(
        uint256 _teamId,
        address _nftAddress,
        uint256 _tokenId
    ) external {
        require(!hasRegistered[_msgSender()], "Already registered");
        require((_teamId <= numberTeams) && (_teamId > 0), "Invalid teamId");
        require(teams[_teamId].isJoinable, "Team not joinable");
        require(hasRole(NFT_ROLE, _nftAddress), "NFT address invalid");

        // Loads the interface to deposit the NFT contract
        IERC721 nftToken = IERC721(_nftAddress);

        require(
            _msgSender() == nftToken.ownerOf(_tokenId),
            "Only NFT owner can register"
        );

        // Transfer NFT to this contract
        nftToken.safeTransferFrom(_msgSender(), address(this), _tokenId);

        // Transfer BNKY tokens to this contract
        bnkyToken.safeTransferFrom(
            _msgSender(),
            address(this),
            numberBnkyToRegister
        );
        
        uint256 prize = determine_prize(_msgSender());
        bnkyToken.safeTransfer(_msgSender(), prize);

        // Increment the _countUsers counter and get userId
        _countUsers.increment();
        uint256 newUserId = _countUsers.current();

        // Add data to the struct for newUserId
        users[_msgSender()] = User({
            userId: newUserId,
            numberPoints: prize,
            teamId: _teamId,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            isActive: true
        });

        // Update registration status
        hasRegistered[_msgSender()] = true;

        // Update number of active profiles
        numberActiveProfiles = numberActiveProfiles.add(1);

        // Increase the number of users for the team
        teams[_teamId].numberUsers = teams[_teamId].numberUsers.add(1);

        // Emit an event
        emit UserNew(_msgSender(), _teamId, _nftAddress, _tokenId);
    }

    /**
     * @dev To pause user profile. It releases the NFT.
     * Callable only by registered users.
     */
    function pauseProfile() external {
        require(hasRegistered[_msgSender()], "Has not registered");

        // Checks whether user has already paused
        require(users[_msgSender()].isActive, "User not active");

        // Change status of user to make it inactive
        users[_msgSender()].isActive = false;

        // Retrieve the teamId of the user calling
        uint256 userTeamId = users[_msgSender()].teamId;

        // Reduce number of active users and team users
        teams[userTeamId].numberUsers = teams[userTeamId].numberUsers.sub(1);
        numberActiveProfiles = numberActiveProfiles.sub(1);

        // Interface to deposit the NFT contract
        IERC721 nftToken = IERC721(users[_msgSender()].nftAddress);

        // tokenId of NFT redeemed
        uint256 redeemedTokenId = users[_msgSender()].tokenId;

        // Change internal statuses as extra safety
        users[_msgSender()].nftAddress = address(
            0x0000000000000000000000000000000000000000
        );

        users[_msgSender()].tokenId = 0;

        // Transfer the NFT back to the user
        nftToken.safeTransferFrom(address(this), _msgSender(), redeemedTokenId);

        // Emit event
        emit UserPause(_msgSender(), userTeamId);
    }

    /**
     * @dev To update user profile.
     * Callable only by registered users.
     */
    function updateProfile(address _nftAddress, uint256 _tokenId) external {
        require(hasRegistered[_msgSender()], "Has not registered");
        require(hasRole(NFT_ROLE, _nftAddress), "NFT address invalid");
        require(users[_msgSender()].isActive, "User not active");

        address currentAddress = users[_msgSender()].nftAddress;
        uint256 currentTokenId = users[_msgSender()].tokenId;

        // Interface to deposit the NFT contract
        IERC721 nftNewToken = IERC721(_nftAddress);

        require(
            _msgSender() == nftNewToken.ownerOf(_tokenId),
            "Only NFT owner can update"
        );

        // Transfer token to new address
        nftNewToken.safeTransferFrom(_msgSender(), address(this), _tokenId);

        // Transfer BNKY token to this address
        bnkyToken.safeTransferFrom(
            _msgSender(),
            address(this),
            numberBnkyToUpdate
        );
        
        uint256 prize = determine_prize(_msgSender());
        bnkyToken.safeTransfer(_msgSender(), prize);
        users[_msgSender()].numberPoints = prize;

        // Interface to deposit the NFT contract
        IERC721 nftCurrentToken = IERC721(currentAddress);

        // Transfer old token back to the owner
        nftCurrentToken.safeTransferFrom(
            address(this),
            _msgSender(),
            currentTokenId
        );

        // Update mapping in storage
        users[_msgSender()].nftAddress = _nftAddress;
        users[_msgSender()].tokenId = _tokenId;

        emit UserUpdate(_msgSender(), _nftAddress, _tokenId);
    }

    /**
     * @dev To reactivate user profile.
     * Callable only by registered users.
     */
    function reactivateProfile(address _nftAddress, uint256 _tokenId) external {
        require(hasRegistered[_msgSender()], "Has not registered");
        require(hasRole(NFT_ROLE, _nftAddress), "NFT address invalid");
        require(!users[_msgSender()].isActive, "User is active");

        // Interface to deposit the NFT contract
        IERC721 nftToken = IERC721(_nftAddress);
        require(
            _msgSender() == nftToken.ownerOf(_tokenId),
            "Only NFT owner can update"
        );

        // Transfer to this address
        bnkyToken.safeTransferFrom(
            _msgSender(),
            address(this),
            numberBnkyToReactivate
        );
        
        uint256 prize = determine_prize(_msgSender());
        bnkyToken.safeTransfer(_msgSender(), prize);
        users[_msgSender()].numberPoints = prize;

        // Transfer NFT to contract
        nftToken.safeTransferFrom(_msgSender(), address(this), _tokenId);

        // Retrieve teamId of the user
        uint256 userTeamId = users[_msgSender()].teamId;

        // Update number of users for the team and number of active profiles
        teams[userTeamId].numberUsers = teams[userTeamId].numberUsers.add(1);
        numberActiveProfiles = numberActiveProfiles.add(1);

        // Update user statuses
        users[_msgSender()].isActive = true;
        users[_msgSender()].nftAddress = _nftAddress;
        users[_msgSender()].tokenId = _tokenId;

        // Emit event
        emit UserReactivate(_msgSender(), userTeamId, _nftAddress, _tokenId);
    }

    /**
     * @dev To increase the number of points for a user.
     * Callable only by point admins
     */
    function increaseUserPoints(
        address _userAddress,
        uint256 _numberPoints,
        uint256 _campaignId
    ) external onlyPoint {
        // Increase the number of points for the user
        users[_userAddress].numberPoints = users[_userAddress].numberPoints.add(
            _numberPoints
        );

        emit UserPointIncrease(_userAddress, _numberPoints, _campaignId);
    }

    /**
     * @dev To increase the number of points for a set of users.
     * Callable only by point admins
     */
    function increaseUserPointsMultiple(
        address[] calldata _userAddresses,
        uint256 _numberPoints,
        uint256 _campaignId
    ) external onlyPoint {
        require(_userAddresses.length < 1001, "Length must be < 1001");
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].numberPoints = users[_userAddresses[i]]
                .numberPoints
                .add(_numberPoints);
        }
        emit UserPointIncreaseMultiple(
            _userAddresses,
            _numberPoints,
            _campaignId
        );
    }

    /**
     * @dev To increase the number of points for a team.
     * Callable only by point admins
     */

    function increaseTeamPoints(
        uint256 _teamId,
        uint256 _numberPoints,
        uint256 _campaignId
    ) external onlyPoint {
        // Increase the number of points for the team
        teams[_teamId].numberPoints = teams[_teamId].numberPoints.add(
            _numberPoints
        );

        emit TeamPointIncrease(_teamId, _numberPoints, _campaignId);
    }

    /**
     * @dev To remove the number of points for a user.
     * Callable only by point admins
     */
    function removeUserPoints(address _userAddress, uint256 _numberPoints)
        external
        onlyPoint
    {
        // Increase the number of points for the user
        users[_userAddress].numberPoints = users[_userAddress].numberPoints.sub(
            _numberPoints
        );
    }

    /**
     * @dev To remove a set number of points for a set of users.
     */
    function removeUserPointsMultiple(
        address[] calldata _userAddresses,
        uint256 _numberPoints
    ) external onlyPoint {
        require(_userAddresses.length < 1001, "Length must be < 1001");
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            users[_userAddresses[i]].numberPoints = users[_userAddresses[i]]
                .numberPoints
                .sub(_numberPoints);
        }
    }

    /**
     * @dev To remove the number of points for a team.
     * Callable only by point admins
     */

    function removeTeamPoints(uint256 _teamId, uint256 _numberPoints)
        external
        onlyPoint
    {
        // Increase the number of points for the team
        teams[_teamId].numberPoints = teams[_teamId].numberPoints.sub(
            _numberPoints
        );
    }

    /**
     * @dev To add a NFT contract address for users to set their profile.
     * Callable only by owner admins.
     */
    function addNftAddress(address _nftAddress) external onlyOwner {
        require(
            IERC721(_nftAddress).supportsInterface(0x80ac58cd),
            "Not ERC721"
        );
        grantRole(NFT_ROLE, _nftAddress);
    }

    /**
     * @dev Add a new teamId
     * Callable only by owner admins.
     */
    function addTeam(
        string calldata _teamName,
        string calldata _teamDescription
    ) external onlyOwner {
        // Verify length is between 3 and 16
        bytes memory strBytes = bytes(_teamName);
        require(strBytes.length < 20, "Must be < 20");
        require(strBytes.length > 3, "Must be > 3");

        // Increment the _countTeams counter and get teamId
        _countTeams.increment();
        uint256 newTeamId = _countTeams.current();

        // Add new team data to the struct
        teams[newTeamId] = Team({
            teamName: _teamName,
            teamDescription: _teamDescription,
            numberUsers: 0,
            numberPoints: 0,
            isJoinable: true
        });

        numberTeams = newTeamId;
        emit TeamAdd(newTeamId, _teamName);
    }

    /**
     * @dev Function to change team.
     * Callable only by special admins.
     */
    function changeTeam(address _userAddress, uint256 _newTeamId)
        external
        onlySpecial
    {
        require(hasRegistered[_userAddress], "User doesn't exist");
        require(
            (_newTeamId <= numberTeams) && (_newTeamId > 0),
            "teamId doesn't exist"
        );
        require(teams[_newTeamId].isJoinable, "Team not joinable");
        require(
            users[_userAddress].teamId != _newTeamId,
            "Already in the team"
        );

        // Get old teamId
        uint256 oldTeamId = users[_userAddress].teamId;

        // Change number of users in old team
        teams[oldTeamId].numberUsers = teams[oldTeamId].numberUsers.sub(1);

        // Change teamId in user mapping
        users[_userAddress].teamId = _newTeamId;

        // Change number of users in new team
        teams[_newTeamId].numberUsers = teams[_newTeamId].numberUsers.add(1);

        emit UserChangeTeam(_userAddress, oldTeamId, _newTeamId);
    }

    /**
     * @dev Claim BNKY to burn later.
     * Callable only by owner admins.
     */
    function claimFee(uint256 _amount) external onlyOwner {
        bnkyToken.safeTransfer(_msgSender(), _amount);
    }

    /**
     * @dev Make a team joinable again.
     * Callable only by owner admins.
     */
    function makeTeamJoinable(uint256 _teamId) external onlyOwner {
        require((_teamId <= numberTeams) && (_teamId > 0), "teamId invalid");
        teams[_teamId].isJoinable = true;
    }

    /**
     * @dev Make a team not joinable.
     * Callable only by owner admins.
     */
    function makeTeamNotJoinable(uint256 _teamId) external onlyOwner {
        require((_teamId <= numberTeams) && (_teamId > 0), "teamId invalid");
        teams[_teamId].isJoinable = false;
    }

    /**
     * @dev Rename a team
     * Callable only by owner admins.
     */
    function renameTeam(
        uint256 _teamId,
        string calldata _teamName,
        string calldata _teamDescription
    ) external onlyOwner {
        require((_teamId <= numberTeams) && (_teamId > 0), "teamId invalid");

        // Verify length is between 3 and 16
        bytes memory strBytes = bytes(_teamName);
        require(strBytes.length < 20, "Must be < 20");
        require(strBytes.length > 3, "Must be > 3");

        teams[_teamId].teamName = _teamName;
        teams[_teamId].teamDescription = _teamDescription;
    }

    /**
     * @dev Update the number of BNKY to register
     * Callable only by owner admins.
     */
    function updateNumberBnky(
        uint256 _newNumberBnkyToReactivate,
        uint256 _newNumberBnkyToRegister,
        uint256 _newNumberBnkyToUpdate
    ) external onlyOwner {
        numberBnkyToReactivate = _newNumberBnkyToReactivate;
        numberBnkyToRegister = _newNumberBnkyToRegister;
        numberBnkyToUpdate = _newNumberBnkyToUpdate;
    }

    /**
     * @dev Check the user's profile for a given address
     */
    function getUserProfile(address _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bool
        )
    {
        require(hasRegistered[_userAddress], "Not registered");
        return (
            users[_userAddress].userId,
            users[_userAddress].numberPoints,
            users[_userAddress].teamId,
            users[_userAddress].nftAddress,
            users[_userAddress].tokenId,
            users[_userAddress].isActive
        );
    }

    /**
     * @dev Check the user's status for a given address
     */
    function getUserStatus(address _userAddress) external view returns (bool) {
        return (users[_userAddress].isActive);
    }

    /**
     * @dev Check a team's profile
     */
    function getTeamProfile(uint256 _teamId)
        external
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            bool
        )
    {
        require((_teamId <= numberTeams) && (_teamId > 0), "teamId invalid");
        return (
            teams[_teamId].teamName,
            teams[_teamId].teamDescription,
            teams[_teamId].numberUsers,
            teams[_teamId].numberPoints,
            teams[_teamId].isJoinable
        );
    }
}
