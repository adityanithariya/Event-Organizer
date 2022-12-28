// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

struct Event {
    address organizer;
    string name;
    uint256 date;
    uint256 price;
    uint256 ticketCount;
    uint256 ticketRemain;
    uint256 ticketsReturned;
}

struct Attendee {
    string attendeeName;
    uint256 ticketsPurchased;
    uint256 amountPaid;
}

contract EventContract {
    mapping(uint256 => Event) public events;
    mapping(address => mapping(uint256 => Attendee)) public tickets;
    uint256 nextId;

    function createEvent(
        string memory name,
        uint256 date,
        uint256 ticketPrice,
        uint256 ticketCount
    ) external payable returns (string memory) {
        require(
            date > block.timestamp,
            "You can organize the event for future dates!"
        );
        require(
            ticketCount > 0,
            "You can't create an event with zero tickets!"
        );
        require(
            msg.value >= (51200 * 1000000000),
            "Event registration price is 51200 gwei!"
        );
        events[nextId] = Event(
            msg.sender,
            name,
            date,
            ticketPrice * 1000000000,
            ticketCount,
            ticketCount,
            0
        );
        nextId++;
        if (msg.value > 51200000000000) {
            payable(msg.sender).transfer(msg.value - 51200000000000);
        }
        return "Your event has been successfully registered!";
    }

    function checkTickets(uint256 eventId)
        external
        view
        returns (
            bool event_exists,
            string memory name,
            string memory ticketPrice,
            uint256 ticketsRemaining
        )
    {
        Event storage _event = events[eventId];
        if (_event.date == 0) {
            return (false, "Event doesn't exists!", "0", 0);
        } else
            return (
                true,
                _event.name,
                string(
                    abi.encodePacked(
                        Strings.toString(_event.price / 1000000000),
                        " gwei"
                    )
                ),
                _event.ticketRemain
            );
    }

    function buyTicket(
        uint256 eventId,
        string memory _attendeeName,
        uint256 _quantity
    ) external payable returns (string memory) {
        Event storage _event = events[eventId];
        require(_event.date != 0, "This event doesn't exist!");
        require(_event.date > block.timestamp, "Event Completed!");
        require(
            _quantity > 0,
            "You have to buy at least one ticket to register for the event!"
        );

        uint256 totalAmount = (_quantity * _event.price);
        require(
            msg.value >= totalAmount,
            string(
                abi.encodePacked(
                    "You have to pay ",
                    Strings.toString(totalAmount / 1000000000),
                    " gwei to buy ",
                    Strings.toString(_quantity),
                    " tickets!"
                )
            )
        );
        require(_event.ticketRemain >= _quantity, "0 tickets left!");

        _event.ticketRemain -= _quantity;

        Attendee memory _attendee = Attendee({
            attendeeName: _attendeeName,
            ticketsPurchased: tickets[msg.sender][eventId].ticketsPurchased +
                _quantity,
            amountPaid: tickets[msg.sender][eventId].amountPaid + totalAmount
        });
        tickets[msg.sender][eventId] = _attendee;

        // Return extra amount, if any
        if (msg.value > totalAmount)
            payable(msg.sender).transfer(msg.value - totalAmount);
        return "Successfully registered for the event!";
    }

    function transferTickets(
        uint256 eventId,
        uint256 _quantity,
        address to,
        string memory _attendeeName
    ) external returns (string memory) {
        Event storage _event = events[eventId];
        require(_event.date != 0, "This event doesn't exist!");
        require(_event.date > block.timestamp, "Event Completed!");
        require(
            _quantity > 0,
            "You have to buy at least one ticket to register for the event!"
        );
        require(
            tickets[msg.sender][eventId].ticketsPurchased >= _quantity,
            "You don't have enough tickets!"
        );
        uint256 totalAmount = (events[eventId].price * _quantity);
        tickets[msg.sender][eventId] = Attendee({
            attendeeName: tickets[msg.sender][eventId].attendeeName,
            ticketsPurchased: tickets[msg.sender][eventId].ticketsPurchased -
                _quantity,
            amountPaid: tickets[msg.sender][eventId].amountPaid - totalAmount
        });
        tickets[to][eventId] = Attendee({
            attendeeName: _attendeeName,
            ticketsPurchased: tickets[to][eventId].ticketsPurchased + _quantity,
            amountPaid: tickets[to][eventId].amountPaid + totalAmount
        });
        return "Successfully Transfered Tickets!";
    }

    function getTicketsMoney(uint256 eventId) external {
        Event storage _event = events[eventId];
        require(
            msg.sender == _event.organizer,
            "You are not verified organizer, try using verified account!"
        );
        uint256 ticketsSold = _event.ticketCount - _event.ticketRemain;
        uint256 amountToPay = (_event.price * ticketsSold * 1000000000) -
            (_event.ticketsReturned * _event.price);
        // return amountToPay;
        require(
            amountToPay > 0,
            "You have taken money of all the tickets sold till now, try again after some tickets are sold!"
        );
        payable(msg.sender).transfer(amountToPay);
    }

    function getTicketsSold(uint256 eventId)
        external
        view
        returns (string memory)
    {
        require(
            msg.sender == events[eventId].organizer,
            "You are not verified organizer, try using verified account!"
        );
        return (
            string(
                abi.encodePacked(
                    "Tickets Sold: ",
                    Strings.toString(
                        events[eventId].ticketCount -
                            events[eventId].ticketRemain
                    )
                )
            )
        );
    }
}
