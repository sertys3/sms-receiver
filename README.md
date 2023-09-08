# Scripts for receiving SMS on a consumer grade SIM bank

## The full story behind this repository may be found here : https://medium.com/@sertys/building-a-128-256-sim-card-bank-with-consumer-tech-on-the-cheap-884ea1b3874c

## SMSTools3 code
I have very slightly modified the SMSTools3 server code to raise a specific alarm for when it successfuly checks a SIM card for messages. I have integrated this into a dashboard to see which SIMs have potential problems( this happens more often that one wishes).

## Installation
The scripts would love to be located in /home/socks folder .
Or you may change paths in the smsd.conf for the handlers to work.

## Iteration
The pool_switch_2.pl script iterates every 200 seconds effectively incrementing the virtual ports in rotation. It however checks for a file in /run/smstools/[PORT NUMBER]_next to hint which port to switch to next. 
I have that integrated into our web app so a user who expects an SMS message on a certain SIM card triggers a file write on the backend and his SIM is checked next.

## USSD commands
There's a pre-set USSD comamnd of *123# in the smsd.conf. This serves a purpose of nudging the SIM card