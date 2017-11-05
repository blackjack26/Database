/**
 * PEP Capping 2017 Algozzine's Class
 *
 * All VIEW entities created to facilitate front-end and server-side queries
 *
 * @author James Crowley, Carson Badame, John Randis, Jesse Opitz,
           Rachel Ulicni & Marcos Barbieri
 * @version 0.2.1
 */

/**
 * PeopleInsert
 *
 * @author John Randis, Marcos Barbieri
 */
 CREATE OR REPLACE FUNCTION PeopleInsert(fname TEXT DEFAULT NULL::text,
         lname TEXT DEFAULT NULL::text,
         mInit VARCHAR DEFAULT NULL::varchar)
         RETURNS INT AS
 $BODY$
     DECLARE
         myId INT;
     BEGIN
         INSERT INTO People(firstName, lastName, middleInit) VALUES (fname, lname, mInit) RETURNING peopleID INTO myId;
         RETURN myId;
     END;
 $BODY$
     LANGUAGE plpgsql VOLATILE;


/**
 * ZipCodeSafeInsert
 *
 * @author Marcos Barbieri
 *
 * TESTED
 */
CREATE OR REPLACE FUNCTION zipCodeSafeInsert(INT, TEXT, STATES) RETURNS VOID AS
$func$
    DECLARE
        zip     INT    := $1;
        city    TEXT   := $2;
        state   STATES   := $3;
    BEGIN
        IF NOT EXISTS (SELECT ZipCodes.zipCode FROM ZipCodes WHERE ZipCodes.zipCode = zip) THEN
            INSERT INTO ZipCodes VALUES (zip, city, CAST(state AS STATES));
        END IF;
    END;
$func$ LANGUAGE plpgsql;


/**
 * RegisterParticipantIntake
 *
 * @author Marcos Barbieri, John Randis
 *
 * @untested
 */
DROP FUNCTION IF EXISTS public.registerparticipantintake(text,
    TEXT,
    DATE,
    TEXT,
    INT,
    TEXT,
    INT,
    INT,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    BOOLEAN,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    BOOLEAN,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    TEXT,
    TEXT,
    TEXT,
    TEXT,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    BOOLEAN,
    BOOLEAN,
    BOOLEAN,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    BOOLEAN,
    TEXT,
    BOOLEAN,
    TEXT,
    DATE,
    DATE,
    DATE,
    TEXT);
CREATE OR REPLACE FUNCTION registerParticipantIntake(
    intakeParticipantID INT DEFAULT NULL::INT,
    intakeParticipantFName TEXT DEFAULT NULL::TEXT,
    intakeParticipantLName TEXT DEFAULT NULL::TEXT,
    intakeParticipantMiddleInit VARCHAR DEFAULT NULL::VARCHAR,
    intakeParticipantDOB DATE DEFAULT NULL::DATE,
    intakeParticipantRace RACE DEFAULT NULL::RACE,
    intakeParticipantSex SEX DEFAULT NULL::SEX,
    housenum INT DEFAULT NULL::INT,
    streetaddress TEXT DEFAULT NULL::TEXT,
    apartmentInfo TEXT DEFAULT NULL::TEXT,
    zipcode INT DEFAULT 12601::INT,
    city TEXT DEFAULT NULL::TEXT,
    state STATES DEFAULT NULL::STATES,
    occupation TEXT DEFAULT NULL::TEXT,
    religion TEXT DEFAULT NULL::TEXT,
    ethnicity TEXT DEFAULT NULL::TEXT,
    handicapsormedication TEXT DEFAULT NULL::TEXT,
    lastyearschool TEXT DEFAULT NULL::TEXT,
    hasdrugabusehist BOOLEAN DEFAULT NULL::BOOLEAN,
    substanceabusedescr TEXT DEFAULT NULL::TEXT,
    timeseparatedfromchildren TEXT DEFAULT NULL::TEXT,
    timeseparatedfrompartner TEXT DEFAULT NULL::TEXT,
    relationshiptootherparent TEXT DEFAULT NULL::TEXT,
    hasparentingpartnershiphistory BOOLEAN DEFAULT NULL::BOOLEAN,
    hasInvolvementCPS BOOLEAN DEFAULT NULL::BOOLEAN,
    hasprevinvolvmentcps text DEFAULT NULL::TEXT,
    ismandatedtotakeclass BOOLEAN DEFAULT NULL::BOOLEAN,
    whomandatedclass TEXT DEFAULT NULL::TEXT,
    reasonforattendence TEXT DEFAULT NULL::TEXT,
    safeparticipate TEXT DEFAULT NULL::TEXT,
    preventparticipate TEXT DEFAULT NULL::TEXT,
    hasattendedotherparenting BOOLEAN DEFAULT NULL::BOOLEAN,
    kindofparentingclasstaken TEXT DEFAULT NULL::TEXT,
    victimchildabuse BOOLEAN DEFAULT NULL::BOOLEAN,
    formofchildhoodabuse TEXT DEFAULT NULL::TEXT,
    hashadtherapy BOOLEAN DEFAULT NULL::BOOLEAN,
    stillissuesfromchildabuse BOOLEAN DEFAULT NULL::BOOLEAN,
    mostimportantliketolearn TEXT DEFAULT NULL::TEXT,
    hasdomesticviolencehistory BOOLEAN DEFAULT NULL::BOOLEAN,
    hasdiscusseddomesticviolence BOOLEAN DEFAULT NULL::BOOLEAN,
    hashistorychildabuseoriginfam BOOLEAN DEFAULT NULL::BOOLEAN,
    hashistoryviolencenuclearfamily BOOLEAN DEFAULT NULL::BOOLEAN,
    ordersofprotectioninvolved BOOLEAN DEFAULT NULL::BOOLEAN,
    reasonforordersofprotection TEXT DEFAULT NULL::TEXT,
    hasbeenarrested BOOLEAN DEFAULT NULL::BOOLEAN,
    hasbeenconvicted BOOLEAN DEFAULT NULL::BOOLEAN,
    reasonforarrestorconviction TEXT DEFAULT NULL::text,
    hasjailrecord BOOLEAN DEFAULT NULL::BOOLEAN,
    hasprisonrecord BOOLEAN DEFAULT NULL::BOOLEAN,
    offensejailprisonrec TEXT DEFAULT NULL::TEXT,
    currentlyonparole BOOLEAN DEFAULT NULL::BOOLEAN,
    onparoleforwhatoffense TEXT DEFAULT NULL::TEXT,
    ptpmainformsigneddate DATE DEFAULT NULL::DATE,
    ptpenrollmentsigneddate DATE DEFAULT NULL::DATE,
    ptpconstentreleaseformsigneddate DATE DEFAULT NULL::DATE,
    eID INT DEFAULT NULL::INT)
  RETURNS void AS
$BODY$
    DECLARE
        pID                    INT;
        adrID                            INT;
        signedDate                       DATE;
        formID                           INT;
    BEGIN
        -- First make sure that the employee is in the database. We don't want to authorize dirty inserts
        PERFORM Employees.employeeID
        FROM Employees
        WHERE Employees.employeeID = eID;
        -- if the employee is not found then raise an exception
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Was not able to find employee with the following ID: %', eID;
        END IF;

        -- Now check if the participant already exists in the system
        PERFORM Participants.participantID
        FROM Participants
        WHERE Participants.participantID = intakeParticipantID;
        -- if they are not found, then go ahead and create that person
        IF NOT FOUND THEN
            INSERT INTO Participants VALUES (intakeParticipantID,
                                            intakeParticipantDOB,
                                            intakeParticipantRace,
                                            intakeParticipantSex);
        END IF;

        -- Now we need to check if a Forms entity was made for the participant
        PERFORM Forms.formID
        FROM Forms
        WHERE Forms.participantID = intakeParticipantID;
        -- if not found go ahead and create the form (perhaps we should put this
        -- in a function for modularity)
        IF NOT FOUND THEN
            -- Handling anything relating to Address/Location information
            PERFORM zipCodeSafeInsert(registerParticipantIntake.zipCode, city, state);
            -- Insert the listed address
            INSERT INTO Addresses(addressNumber, street, aptInfo, zipCode)
            VALUES (houseNum, streetAddress, apartmentInfo, registerParticipantIntake.zipCode)
            RETURNING addressID INTO adrID;

            -- Fill in the actual form information
            RAISE NOTICE 'address %', adrID;
            signedDate := (current_date);
            INSERT INTO Forms(addressID, employeeSignedDate, employeeID, participantID) VALUES (adrID, signedDate, eID, pID);
            formID := (SELECT Forms.formID FROM Forms WHERE Forms.addressID = adrID AND
                                                            Forms.employeeSignedDate = signedDate AND
                                                            Forms.employeeID = eID);
            RAISE NOTICE 'formID %', formID;
        END IF;

        -- Finally we can create the intake information
        INSERT INTO IntakeInformation VALUES (formID,
                                              occupation,
                                              religion,
                                              ethnicity,
                                              handicapsOrMedication,
                                              lastYearSchool,
                                              hasDrugAbuseHist,
                                              substanceAbuseDescr,
                                              timeSeparatedFromChildren,
                                              timeSeparatedFromPartner,
                                              relationshipToOtherParent,
                                              hasParentingPartnershipHistory,
                                              hasInvolvementCPS,
                                              hasPrevInvolvmentCPS,
                                              isMandatedToTakeClass,
                                              whoMandatedClass,
                                              reasonForAttendence,
                                              safeParticipate,
                                              preventParticipate,
                                              hasAttendedOtherParenting,
                                              kindOfParentingClassTaken,
                                              victimChildAbuse,
                                              formOfChildhoodAbuse,
                                              hasHadTherapy,
                                              stillIssuesFromChildAbuse,
                                              mostImportantLikeToLearn,
                                              hasDomesticViolenceHistory,
                                              hasDiscussedDomesticViolence,
                                              hasHistoryChildAbuseOriginFam,
                                              hasHistoryViolenceNuclearFamily,
                                              ordersOfProtectionInvolved,
                                              reasonForOrdersOfProtection,
                                              hasBeenArrested,
                                              hasBeenConvicted,
                                              reasonForArrestOrConviction,
                                              hasJailRecord,
                                              hasPrisonRecord,
                                              offenseJailPrisonRec,
                                              currentlyOnParole,
                                              onParoleForWhatOffense,
                                              ptpMainFormSignedDate,
                                              ptpEnrollmentSignedDate,
                                              ptpConstentReleaseFormSignedDate
                                          );
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

/**
 * Employee
 * @author Carson Badame
 *
 * Inserts a new person to the Employees table and links them with an id in the People table.
 *
 * TESTED
 */
CREATE OR REPLACE FUNCTION employeeInsert(
    fname TEXT DEFAULT NULL::text,
    lname TEXT DEFAULT NULL::text,
    mInit VARCHAR DEFAULT NULL::varchar,
    em TEXT DEFAULT NULL::text,
    pPhone TEXT DEFAULT NULL::text,
    pLevel PERMISSION DEFAULT 'Coordinator'::PERMISSION)
RETURNS VOID AS
$BODY$
    DECLARE
        eID INT;
    BEGIN
        PERFORM Employees.employeeID FROM People, Employees WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit AND People.peopleID = Employees.employeeID;
        IF FOUND THEN
            RAISE NOTICE 'Employee already exists.';
        ELSE
            -- Checks to see if new employee already exists in People table
            PERFORM People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit;
            -- If they do, insert link them to peopleID and insert into Employees table
            IF FOUND THEN
                eID := (SELECT People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit= mInit);
                RAISE NOTICE 'people %', eID;
                INSERT INTO Employees(employeeID, email, primaryPhone, permissionLevel) VALUES (eID, em, pPhone, pLevel);
            -- Else create new person in People table and then insert them into Employees table
            ELSE
                INSERT INTO People(firstName, lastName, middleInit) VALUES (fname, lname, mInit);
                eID := (SELECT People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit);
                RAISE NOTICE 'people %', eID;
                INSERT INTO Employees(employeeID, email, primaryPhone, permissionLevel) VALUES (eID, em, pPhone, pLevel);
            END IF;
        END IF;
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * Facilitator
 * @author Carson Badame
 *
 * Inserts a new person to the Facilitators table and links them with an id in the Employees and People tables.
 *
 * TESTED
 */
CREATE OR REPLACE FUNCTION facilitatorInsert(
    fname TEXT DEFAULT NULL::text,
    lname TEXT DEFAULT NULL::text,
    mInit VARCHAR DEFAULT NULL::varchar,
    em TEXT DEFAULT NULL::text,
    pPhone TEXT DEFAULT NULL::text,
    pLevel PERMISSION DEFAULT 'Coordinator'::PERMISSION)
RETURNS VOID AS
$BODY$
    DECLARE
        fID INT;
        eReturn TEXT;
    BEGIN
    -- Check to see if the facilitator already exists
        PERFORM Facilitators.facilitatorID FROM People, Employees, Facilitators WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit AND People.peopleID = Employees.employeeID AND Employees.employeeID = Facilitators.facilitatorID;
        -- If they do, do need insert anything
        IF FOUND THEN
            RAISE NOTICE 'Facilitator already exists.';
        ELSE
            -- If they do not, check to see if they exists as an employee
            PERFORM Employees.employeeID FROM Employees, People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit AND People.peopleID = Employees.employeeID;
            -- If they do, then add the facilitator and link them to the employee
            IF FOUND THEN
                fID := (SELECT Employees.employeeID FROM Employees, People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit AND People.peopleID = Employees.employeeID);
                RAISE NOTICE 'employee %', fID;
                INSERT INTO Facilitators(facilitatorID) VALUES (fID);
            -- If they do not, run the employeeInsert function and then add the facilitator
            ELSE
                SELECT employeeInsert(fname, lname, mInit, em, pPhone, pLevel) INTO eReturn;
                fID := (SELECT Employees.employeeID FROM Employees, People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit AND People.peopleID = Employees.employeeID);
                RAISE NOTICE 'employee %', fID;
                INSERT INTO Facilitators(facilitatorID) VALUES (fID);
            END IF;
        END IF;
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * Agency Member
 * @author John Randis and Carson Badame
 *
 * Inserts a new person to the ContactAgencyMembers table and links them with an id in the People table.
 *
 * TESTED
 */
CREATE OR REPLACE FUNCTION agencyMemberInsert(
    fname TEXT DEFAULT NULL::text,
    lname TEXT DEFAULT NULL::text,
    mInit VARCHAR DEFAULT NULL::varchar,
    agen REFERRALTYPE DEFAULT NULL::referraltype,
    phn INT DEFAULT NULL::int,
    em TEXT DEFAULT NULL::text,
    isMain BOOLEAN DEFAULT NULL::boolean,
    arID INT DEFAULT NULL::int)
RETURNS VOID AS
$BODY$
    DECLARE
        caID INT;
        pReturn TEXT;
    BEGIN
    -- Check to see if the agency member already exists
        PERFORM ContactAgencyMembers.contactAgencyID FROM ContactAgencyMembers, People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit AND People.peopleID = ContactAgencyMembers.contactAgencyID;
        -- If they do, do not insert anything
        IF FOUND THEN
            RAISE NOTICE 'Agency member already exists.';
        ELSE
            -- If they do not, check to see if they exists as an a person
            PERFORM People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit;
            -- If they do, then add the agency member and link them to the employee
            IF FOUND THEN
                caID := (SELECT People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit);
                RAISE NOTICE 'AgencyMember %', caID;
                INSERT INTO ContactAgencyMembers(contactAgencyID, agency, phone, email) VALUES (caID, agen, phn, em);
                INSERT INTO ContactAgencyAssociatedWithReferred(contactAgencyID, agencyReferralID, isMainContact) VALUES (caID, arID, isMain);
            -- If they do not, run create the person and then add them as an agency member
            ELSE
                INSERT INTO People(firstName, lastName, middleInit) VALUES (fname, lname, mInit);
                caID := (SELECT People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit);
                RAISE NOTICE 'AgencyMember %', caID;
                INSERT INTO ContactAgencyMembers(contactAgencyID, agency, phone, email) VALUES (caID, agen, phn, em);
                INSERT INTO ContactAgencyAssociatedWithReferred(contactAgencyID, agencyReferralID, isMainContact) VALUES (caID, arID, isMain);
            END IF;
        END IF;
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * @author John Randis, Carson Badame, Marcos Barbieri
 * @untested
 */
CREATE OR REPLACE FUNCTION addAgencyReferral(
  agencyReferralParticipantID INTEGER DEFAULT NULL::INTEGER,
  agencyReferralParticipantDateOfBirth DATE DEFAULT NULL::DATE,
  agencyReferralParticipantSex SEX DEFAULT NULL::SEX,
  agencyReferralParticipantRace RACE DEFAULT NULL::RACE,
  housenum INTEGER DEFAULT NULL::INTEGER,
  streetaddress TEXT DEFAULT NULL::TEXT,
  apartmentInfo TEXT DEFAULT NULL::TEXT,
  zipcode INTEGER DEFAULT NULL::INTEGER,
  city TEXT DEFAULT NULL::TEXT,
  state STATES DEFAULT NULL::STATES,
  referralReason TEXT DEFAULT NULL::TEXT,
  hasAgencyConsentForm BOOLEAN DEFAULT FALSE::BOOLEAN,
  referringAgency TEXT DEFAULT NULL::TEXT,
  referringAgencyDate DATE DEFAULT NULL::DATE,
  additionalInfo TEXT DEFAULT NULL::TEXT,
  hasSpecialNeeds BOOLEAN DEFAULT NULL::BOOLEAN,
  hasSubstanceAbuseHistory BOOLEAN DEFAULT NULL::BOOLEAN,
  hasInvolvementCPS BOOLEAN DEFAULT NULL::BOOLEAN,
  isPregnant BOOLEAN DEFAULT NULL::BOOLEAN,
  hasIQDoc BOOLEAN DEFAULT NULL::BOOLEAN,
  mentalHealthIssue BOOLEAN DEFAULT NULL::BOOLEAN,
  hasDomesticViolenceHistory BOOLEAN DEFAULT NULL::BOOLEAN,
  childrenLiveWithIndividual BOOLEAN DEFAULT NULL::BOOLEAN,
  dateFirstContact DATE DEFAULT NULL::DATE,
  meansOfContact TEXT DEFAULT NULL::TEXT,
  dateOfInitialMeeting TIMESTAMP DEFAULT NULL::DATE,
  location TEXT DEFAULT NULL::TEXT,
  comments TEXT DEFAULT NULL::TEXT,
  eID INT DEFAULT NULL::INT)
RETURNS TABLE(pID INT, fID INT) AS
    $BODY$
        DECLARE
            newparticipantID   INT;
            agencyReferralID  INT;
            contactAgencyID   INT;
            adrID               INT;
            signedDate          DATE;
            newformID        INT;
            participantReturn TEXT;
        BEGIN
            -- First make sure that the employee is in the database. We don't want to authorize dirty inserts
            PERFORM Employees.employeeID
            FROM Employees
            WHERE Employees.employeeID = eID;
            -- if the employee is not found then raise an exception
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Was not able to find employee with the following ID: %', eID;
            END IF;

            -- Now check if the participant already exists in the system
            PERFORM Participants.participantID
            FROM Participants
            WHERE Participants.participantID = intakeParticipantID;
            -- if they are not found, then go ahead and create that person
            IF NOT FOUND THEN
                INSERT INTO Participants VALUES (agencyReferralParticipantID,
                                                 agencyReferralParticipantDateOfBirth,
                                                 agencyReferralParticipantRace,
                                                 agencyReferralParticipantSex);
            END IF;

            -- Now we need to check if a Forms entity was made for the participant
            PERFORM Forms.formID
            FROM Forms
            WHERE Forms.participantID = intakeParticipantID;
            -- if not found go ahead and create the form (perhaps we should put this
            -- in a function for modularity)
            IF NOT FOUND THEN
                -- Handling anything relating to Address/Location information
                PERFORM zipCodeSafeInsert(registerParticipantIntake.zipCode, city, state);
                -- Insert the listed address
                INSERT INTO Addresses(addressNumber, street, aptInfo, zipCode)
                VALUES (houseNum, streetAddress, apartmentInfo, registerParticipantIntake.zipCode)
                RETURNING addressID INTO adrID;

                -- Fill in the actual form information
                RAISE NOTICE 'address %', adrID;
                signedDate := (current_date);
                INSERT INTO Forms(addressID, employeeSignedDate, employeeID, participantID) VALUES (adrID, signedDate, eID, pID);
                newFormID := (SELECT Forms.formID FROM Forms WHERE Forms.addressID = adrID AND
                                                                Forms.employeeSignedDate = signedDate AND
                                                                Forms.employeeID = eID);
                RAISE NOTICE 'formID %', formID;
            END IF;

            -- Assign values to declared variables
            signedDate := (current_date);
            -- Insert the information into the table
            INSERT INTO AgencyReferral VALUES (newformID,
                                               referralReason,
                                               hasAgencyConsentForm,
                                               additionalInfo,
                                               hasSpecialNeeds,
                                               hasSubstanceAbuseHistory,
                                               hasInvolvementCPS,
                                               isPregnant,
                                               hasIQDoc,
                                               mentalHealthIssue,
                                               hasDomesticViolenceHistory,
                                               childrenLiveWithIndividual,
                                               dateFirstContact,
                                               meansOfContact,
                                               dateOfInitialMeeting,
                                               location,
                                               comments);
            -- Finally return the participant ID with the form ID for developer
            -- convenience
            RETURN QUERY (SELECT Participants.participantID, Forms.formID
                          FROM Participants,
                               Forms
                          WHERE Participants.participantID = newparticipantID AND
                                Forms.formID = newformID);

          END;
      $BODY$
LANGUAGE plpgsql VOLATILE;


/**
 * Creates a family member in the database.

 * @author Jesse Opitz
 * @untested
 */
CREATE OR REPLACE FUNCTION createFamilyMember(
    fname TEXT DEFAULT NULL::TEXT,
    lname TEXT DEFAULT NULL::TEXT,
    mInit VARCHAR DEFAULT NULL::VARCHAR,
    rel RELATIONSHIP DEFAULT NULL::RELATIONSHIP,
    dob DATE DEFAULT NULL::DATE,
    race RACE DEFAULT NULL::RACE,
    gender SEX DEFAULT NULL::SEX,
    -- IF child is set to True
    -- -- Inserts child information
    child BOOLEAN DEFAULT NULL::boolean,
    cust TEXT DEFAULT NULL::text,
    loc TEXT DEFAULT NULL::text,
    fID INT DEFAULT NULL::int)
RETURNS VOID AS
$BODY$
    DECLARE
        fmID INT;
        pReturn TEXT;
    BEGIN
        SELECT peopleInsert(fname, lname, mInit) INTO pReturn;
        fmID := (SELECT People.peopleID FROM People WHERE People.firstName = fname AND People.lastName = lname AND People.middleInit = mInit);
        RAISE NOTICE 'FamilyMember %', fmID;
        INSERT INTO FamilyMembers(familyMemberID, relationship, dateOfBirth, racee, sex) VALUES (fmID, rel, dob, race, gender);
        IF child = True THEN
          INSERT INTO Children(childrenID, custody, location) VALUES(fmID, cust, loc);
        END IF;
        INSERT INTO Family(familyMembersID, formID) VALUES (fmID, fID);
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * Creates a participant in the correct order.
 *
 * @author Jesse Opitz
 * @untested
 */
 -- Stored Procedure for Creating Participants
DROP FUNCTION IF EXISTS createParticipants(TEXT, TEXT, VARCHAR, DATE, SEX, RACE);
CREATE OR REPLACE FUNCTION createParticipants(
    fname TEXT DEFAULT NULL::TEXT,
    lname TEXT DEFAULT NULL::TEXT,
    mInit VARCHAR DEFAULT NULL::VARCHAR,
    dob DATE DEFAULT NULL::DATE,
    gender SEX DEFAULT NULL::SEX,
    RACE RACE DEFAULT NULL::RACE)
RETURNS INT AS
$BODY$
    DECLARE
        partID INT;
        myID	INT;
        pReturn TEXT;
    BEGIN
        SELECT peopleInsert(fname, lname, mInit) INTO partID;
        RAISE NOTICE 'people %', partID;
        INSERT INTO Participants(participantID, dateOfBirth, racee, sex) VALUES (partID, dob, race, gender) RETURNING participantID INTO myID;
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * ParticipantAttendanceInsert
 *  Used for inserting the attendance record for a participant for a specific
 *  class offering
 * @returns VOID
 * @author Marcos Barbieri
 * @untested
 */
CREATE OR REPLACE FUNCTION attendanceInsert(
    attendanceParticipantID INT DEFAULT NULL::INT,
    attendantFirstName TEXT DEFAULT NULL::TEXT,
    attendantLastName TEXT DEFAULT NULL::TEXT,
    attendantMiddleInit VARCHAR DEFAULT NULL::VARCHAR,
    attendantAge INT DEFAULT NULL::INT,
    attendanceParticipantRace RACE DEFAULT NULL::RACE,
    attendanceParticipantSex SEX DEFAULT NULL:: SEX,
    attendanceFacilitatorID INT DEFAULT NULL::INT,
    attendanceTopic TEXT DEFAULT NULL::TEXT,
    attendanceDate TIMESTAMP DEFAULT NULL::TIMESTAMP,
    attendanceCurriculum TEXT DEFAULT NULL::TEXT,
    attendanceComments TEXT DEFAULT NULL::TEXT,
    attendanceNumChildren INT DEFAULT NULL::INT,
    isAttendanceNew BOOLEAN DEFAULT NULL::BOOLEAN,
    attendanceParticipantZipCode INT DEFAULT NULL::INT,
    inHouseFlag BOOLEAN DEFAULT FALSE::BOOLEAN
)
RETURNS VOID AS
$BODY$
    BEGIN
        -- first we need to check that the curriculum is created.
        -- we do not allow the creation of a curriculum through attendance
        -- curriculums should be created before the class runs
        PERFORM Curricula.curriculumName
        FROM Curricula
        WHERE Curricula.curriculumName = attendanceCurriculum;
        -- if we don't find it, raise an exception
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Curriculum: % not found', attendanceCurriculum;
        END IF;

        -- now we need to check that the course exists in the system
        PERFORM Classes.topicName
        FROM Classes
        WHERE Classes.topicName = attendanceTopic;
        -- if we don't find the class, raise an exception
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Class: % not found', attendanceTopic;
        END IF;

        -- now check that the facilitator being registered exists
        PERFORM Facilitators.facilitatorID
        FROM Facilitators
        WHERE Facilitators.facilitatorID = attendanceFacilitatorID;
        -- If we don't find it we need to raise an exception
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Facilitator with facilitatorID: % does not exist',
                attendanceFacilitatorID;
        END IF;

        -- Now we need to check if the Class offering that we are registering exists
        PERFORM ClassOffering.topicName
        FROM ClassOffering
        WHERE ClassOffering.topicName=attendanceTopic AND
            ClassOffering.date=attendanceDate AND
            ClassOffering.siteName=attendanceSiteName;
        -- if it isn't found lets create it
        IF NOT FOUND THEN
            -- we will call our stored procedure for this.
            -- this way we can shorten this one and make more checks within the
            -- CreateClassOffering one
            PERFORM CreateClassOffering(
                offeringTopicName := attendanceTopic::TEXT,
                offeringTopicDescription := ''::TEXT,
                offeringTopicDate := attendanceDate::TIMESTAMP,
                attendanceCurriculum := attendanceCurriculum::TEXT,
                offeringLanguage := 'English'::TEXT,
                offeringCurriculumId := NULL::INT);
        END IF;

        -- Now we need to make sure that we didn't already register the
        -- facilitator's attendance
        PERFORM *
        FROM FacilitatorClassAttendance
        WHERE FacilitatorClassAttendance.topicName = attendanceTopic AND
              FacilitatorClassAttendance.date = attendanceDate AND
              FacilitatorClassAttendance.curriculumName = attendanceCurriculum AND
              FacilitatorClassAttendance.facilitatorID = attendanceFacilitatorID;
        -- if we don't find it then we need to register that facilitator's attendance
        IF NOT FOUND THEN
            INSERT INTO FacilitatorClassAttendance
            VALUES (attendanceTopic,
                    attendanceDate,
                    attendanceCurriculum,
                    attendanceFacilitatorID);
        END IF;

        -- now we need to check if the participant exists
        PERFORM Participants.participantID
        FROM Participants
        WHERE Participants.participantID = attendanceParticipantID;
        -- if we don't find the participant lets go ahead and create it
        IF FOUND THEN
            -- this is tricky because we only want to create-if-not-found when we are
            -- dealing with out of house participants. In-house participant should be
            -- created through the creation of a referral/intake
            IF inHouseFlag IS FALSE THEN
                INSERT INTO Participants VALUES (attendanceParticipantID,
                                                 make_date((date_part('year', current_date)-attendantAge)::INT, 1, 1)::DATE,
                                                 attendanceParticipantRace,
                                                 attendanceParticipantSex);
            END IF;
        END IF;

        -- Still need to verify that sitename and topic exist
        RAISE NOTICE 'Inserting record for participant %', attendanceParticipantID;
        INSERT INTO ParticipantClassAttendance VALUES (attendanceTopic,
                                                       attendanceDate,
                                                       attendanceCurriculum,
                                                       attendanceParticipantID,
                                                       attendanceComments,
                                                       attendanceNumChildren,
                                                       isAttendanceNew,
                                                       attendanceParticipantZipCode);
    END
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * CreateClassOffering
 * Creates the class (if necessary) and the class offering for a specific course
 */
CREATE OR REPLACE FUNCTION CreateClassOffering(
    offeringTopicName TEXT DEFAULT NULL::TEXT,
    offeringTopicDescription TEXT DEFAULT NULL::TEXT,
    offeringTopicDate TIMESTAMP DEFAULT NULL::TIMESTAMP,
    offeringCurriculum TEXT DEFAULT NULL::TEXT,
    offeringLanguage TEXT DEFAULT NULL::TEXT,
    offeringCurriculumId INT DEFAULT NULL::INT)
RETURNS VOID AS
$BODY$
BEGIN
    -- first we need to check that the curriculum is created.
    PERFORM Curricula.curriculumName
    FROM Curricula
    WHERE Curricula.curriculumName = attendanceCurriculum;
    -- if we don't find it, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Curriculum: % not found', attendanceCurriculum;
    END IF;

    -- now we need to check that the course exists in the system
    PERFORM Classes.topicName
    FROM Classes
    WHERE Classes.topicName = attendanceTopic;
    -- if we don't find the class, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Class: % not found', attendanceTopic;
    END IF;

    -- insert the necessary data into the ClassOffering table
    INSERT INTO ClassOffering VALUES (offeringTopicName, offeringTopicDate, offeringCurriculum, offeringLanguage, offeringCurriculumId);
END
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * CalculateDOB
 *  Takes the age and subtracets it from the current year to get an age estimate.
 *  The reason we do this is because the PEP program only asks for age on certain
 *  forms, and not DOB. However, age should never be stored, only DOB, so we must
 *  calculate this manually.
 *
 * @author Marcos Barbieri
 *
 * TESTED
 */
 CREATE OR REPLACE FUNCTION calculateDOB(age INT DEFAULT NULL::INT)
 RETURNS INT AS
 $BODY$
    DECLARE
        currentYear INT := date_part('year', CURRENT_DATE);
        dob INT;
    BEGIN
        dob := currentYear - age;
        RETURN dob;
    END
$BODY$
    LANGUAGE plpgsql VOLATILE;

/**
 * Inserts a new referral form to the addSelfReferral table and links them with an id in the Forms, Participants, and People tables.
 *
 * @author Carson Badame
 * @tested
 */
CREATE OR REPLACE FUNCTION addSelfReferral(
    referralParticipantID INT DEFAULT NULL::INT,
    referralFirstName TEXT DEFAULT NULL::TEXT,
    referralLastName TEXT DEFAULT NULL::TEXT,
    referralMiddleInit VARCHAR DEFAULT NULL::VARCHAR,
    referralDOB DATE DEFAULT NULL::DATE,
    referralRace RACE DEFAULT NULL::RACE,
    referralSex SEX DEFAULT NULL::SEX,
    houseNum INT DEFAULT NULL::INT,
    streetAddress TEXT DEFAULT NULL::TEXT,
    apartmentInfo TEXT DEFAULT NULL::TEXT,
    zip INT DEFAULT NULL::INT,
    cityName TEXT DEFAULT NULL::TEXT,
    stateName STATES DEFAULT NULL::STATES,
    refSource TEXT DEFAULT NULL::TEXT,
    hasInvolvement BOOLEAN DEFAULT NULL::BOOLEAN,
    hasAttended BOOLEAN DEFAULT NULL::BOOLEAN,
    reasonAttending TEXT DEFAULT NULL::TEXT,
    firstCall DATE DEFAULT NULL::DATE,
    returnCallDate DATE DEFAULT NULL::DATE,
    startDate DATE DEFAULT NULL::DATE,
    classAssigned TEXT DEFAULT NULL::TEXT,
    letterMailedDate DATE DEFAULT NULL::DATE,
    extraNotes TEXT DEFAULT NULL::TEXT,
    eID INT DEFAULT NULL::INT)
RETURNS VOID AS
$BODY$
    DECLARE
        pID                 INT;
        fID                 INT;
        adrID               INT;
        srID                INT;
        signedDate          DATE;
    BEGIN
        -- First make sure that the employee is in the database. We don't want to authorize dirty inserts
        PERFORM Employees.employeeID
        FROM Employees
        WHERE Employees.employeeID = eID;
        -- if the employee is not found then raise an exception
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Was not able to find employee with the following ID: %', eID;
        END IF;

        -- now check if the participant already exists in the system
        PERFORM Participants.participantID
        FROM Participants
        WHERE Participants.participantID = referralParticipantID;
        -- if they are not found, then go ahead and create that person
        IF NOT FOUND THEN
            INSERT INTO Participants VALUES (referralParticipantID,
                                             referralDOB,
                                             referralRace,
                                             referralSex);
        END IF;

        -- now we need to check if a Forms entity was made for the participant
        PERFORM Forms.formID
        FROM Forms
        WHERE Forms.participantID = intakeParticipantID;
        -- if not found go ahead and create the form (perhaps we should put this
        -- in a function for modularity)
        IF NOT FOUND THEN
            -- Handling anything relating to Address/Location information
            PERFORM zipCodeSafeInsert(registerParticipantIntake.zipCode, city, state);
            -- Insert the listed address
            INSERT INTO Addresses(addressNumber, street, aptInfo, zipCode)
            VALUES (houseNum, streetAddress, apartmentInfo, registerParticipantIntake.zipCode)
            RETURNING addressID INTO adrID;

            -- Fill in the actual form information
            RAISE NOTICE 'address %', adrID;
            signedDate := (current_date);
            INSERT INTO Forms(addressID, employeeSignedDate, employeeID, participantID) VALUES (adrID, signedDate, eID, pID);
            fID := (SELECT Forms.formID FROM Forms WHERE Forms.addressID = adrID AND
                                                            Forms.employeeSignedDate = signedDate AND
                                                            Forms.employeeID = eID);
            RAISE NOTICE 'formID %', formID;
        END IF;

        INSERT INTO SelfReferral VALUES (  fID,
                                           refSource,
                                           hasInvolvement,
                                           hasAttended,
                                           reasonAttending,
                                           firstCall,
                                           returnCallDate,
                                           startDate,
                                           classAssigned,
                                           letterMailedDate,
                                           extraNotes);
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
* CreateEmergencyContact
*   Used to create an emergency contact by other stored procedures
* @returns VOID
* @author Jesse Opitz
*/
DROP FUNCTION IF EXISTS createEmeregencyContact();
CREATE OR REPLACE FUNCTION createEmergencyContact(
    pID INT DEFAULT NULL::int,
    intInfoID INT DEFAULT NULL::int,
    rel RELATIONSHIP DEFAULT NULL::relationship,
    phon TEXT DEFAULT NULL::text
)
RETURNS VOID AS
$BODY$
    DECLARE
    BEGIN
        INSERT INTO EmergencyContacts(emergencyContactID, relationship, phone) VALUES (pID, rel, phon);
        INSERT INTO  EmergencyContactDetail(emergencyContactID, intakeInformationID) VALUES (pID, intInfoID);
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
* CreateCurriculum
*   Links topic to a new curriculum
* @returns VOID
* @author Jesse Opitz
* @untested
*/
DROP FUNCTION IF EXISTS createCurriculum();
CREATE OR REPLACE FUNCTION createCurriculum(
    tnID INT DEFAULT NULL::INT,
    currName TEXT DEFAULT NULL::TEXT,
    currType PROGRAMTYPE DEFAULT NULL::PROGRAMTYPE,
    missNum INT DEFAULT NULL::INT)
RETURNS INT AS
$BODY$
    DECLARE
        cID INT;
    BEGIN
        INSERT INTO Curricula(curriculumName, curriculumType, missNumber) VALUES (currName, currType, missNum);
        SELECT Curricula.curriculumID FROM Curricula WHERE Curriclua.curriculumName = currName AND Curricula.curriculumType = currType AND Curricula.missNumber = missNum INTO cID;
        RETURN cID;
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;


/**
 * createOutOfHouseParticipant
 *  Creates a new Out of House Participant making sure all information is stored
 *  soundly.
 *
 * @returns INT
 * @author Marcos Barbieri, John Randis
 * @untested
 */
DROP FUNCTION IF EXISTS createOutOfHouseParticipant(INT, TEXT, INT);
CREATE OR REPLACE FUNCTION createOutOfHouseParticipant(
    outOfHouseParticipantId INT DEFAULT NULL::INT,
    participantDescription TEXT DEFAULT NULL::TEXT,
    employeeID INT DEFAULT NULL::INT)
RETURNS INT AS
$BODY$
    DECLARE
        dateOfBirth DATE;
        ptpID INT;
    BEGIN
        -- First make sure that the employee is in the database. We don't want to authorize dirty inserts
        PERFORM Employees.employeeID
        FROM Employees
        WHERE Employees.employeeID = employeeID;
        -- if the employee is not found then raise an exception
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Was not able to find employee with the following ID: %', employeeID;
        END IF;

        -- now check if the participant already exists in the system
        PERFORM Participants.participantID
        FROM Participants
        WHERE Participants.participantID = outOfHouseParticipantId;
        -- if they are not found, then go ahead and create that person
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Participant with ID: % does not exist', outOfHouseParticipantId;
        END IF;

        -- now check if the participant already exists in the system
        PERFORM OutOfHouse.outOfHouseID
        FROM OutOfHouse
        WHERE Participants.outOfHouseID = outOfHouseParticipantId;
        -- if they are not found, then go ahead and create that person
        IF FOUND THEN
            RAISE EXCEPTION 'Out-of-House Participant with ID: % already exists', outOfHouseParticipantId;
        END IF;

        INSERT INTO OutOfHouse VALUES (ptpID, participantDescription);
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;

/**
* CreateClass
*   Creates a class linking to a curriculum through the createCurriculum
*   stored procedure.
* @returns VOID
* @author Jesse Opitz, Marcos Barbieri
* @untested
*/
DROP FUNCTION IF EXISTS createClass();
CREATE OR REPLACE FUNCTION createClass(
    className TEXT DEFAULT NULL::TEXT,
    classDescription TEXT DEFAULT NULL::TEXT,
    classCurriculumName TEXT DEFAULT NULL::TEXT)
RETURNS VOID AS
$BODY$
    BEGIN
        -- first we need to check that the curriculum is created
        PERFORM *
        FROM Curricula
        WHERE Curricula.curriculumName = classCurriculumName;
        -- if we don't find it should we create it ? I don't think so
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Curriculum: % was not found', classCurriculumName
                USING HINT = 'Please create a curriculum with the given name';
        END IF;

        -- now we need to check that the class isn't already created
        PERFORM *
        FROM Classes
        WHERE Classes.topicName = className AND
              Classes.description = classDescription;
        IF FOUND THEN
            RAISE EXCEPTION 'A class with the same name and description already exists';
        END IF;

        INSERT INTO Classes VALUES (className, classDescription, 0);
    END;
$BODY$
    LANGUAGE plpgsql VOLATILE;
