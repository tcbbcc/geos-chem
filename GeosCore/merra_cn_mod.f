!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !MODULE: merra_cn_mod
!
! !DESCRIPTION: Module MERRA\_CN\_MOD contains subroutines for reading the 
!  constant (aka "CN") fields from the MERRA data archive.
!\\
!\\
! !INTERFACE: 
!
      MODULE MERRA_CN_MOD
!
! !USES:
!
      IMPLICIT NONE
      PRIVATE

#     include "CMN_SIZE"              ! Size parameters
#     include "CMN_DIAG"              ! NDxx flags
#     include "CMN_GCTM"              ! g0
!
! !PUBLIC MEMBER FUNCTIONS:
! 
      PUBLIC  :: GET_MERRA_CN_FIELDS
      PUBLIC  :: OPEN_MERRA_CN_FIELDS
!
! !PRIVATE MEMBER FUNCTIONS:
! 
      PRIVATE :: CN_CHECK
      PRIVATE :: READ_CN
!
! !REMARKS:
!  Don't bother with the file unzipping anymore.
!
! !REVISION HISTORY:
!  19 Aug 2010 - R. Yantosca - Initial version, based on i6_read_mod.f
!  20 Aug 2010 - R. Yantosca - Moved include files to top of module
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !PRIVATE TYPES:
!
      INTEGER :: N_CN_FIELDS    ! # of fields in the file

      CONTAINS
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: open_merra_cn_fields
!
! !DESCRIPTION: Subroutine OPEN\_MERRA\_CN\_FIELDS opens the MERRA "CN" 
!  met fields file for date NYMD and time NHMS.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE OPEN_MERRA_CN_FIELDS( NYMD, NHMS )
!
! !USES:
!
      USE BPCH2_MOD,     ONLY : GET_RES_EXT
      USE DIRECTORY_MOD, ONLY : DATA_DIR
      USE DIRECTORY_MOD, ONLY : MERRA_DIR
      USE ERROR_MOD,     ONLY : ERROR_STOP
      USE FILE_MOD,      ONLY : FILE_EXISTS
      USE FILE_MOD,      ONLY : IU_CN
      USE FILE_MOD,      ONLY : IOERROR
      USE TIME_MOD,      ONLY : EXPAND_DATE
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN) :: NYMD   ! YYYYMMDD date
      INTEGER, INTENT(IN) :: NHMS   ! hhmmss time
!
! !REVISION HISTORY: 
!  19 Aug 2010 - R. Yantosca - Initial version, based on i6_read_mod.f
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      LOGICAL, SAVE      :: FIRST = .TRUE.
      LOGICAL            :: IT_EXISTS
      INTEGER            :: IOS, IUNIT
      CHARACTER(LEN=8)   :: IDENT
      CHARACTER(LEN=255) :: GEOS_DIR
      CHARACTER(LEN=255) :: CN_FILE
      CHARACTER(LEN=255) :: PATH

      !=================================================================
      ! OPEN_CN_FIELDS begins here!
      !=================================================================

      ! Check if it's time to open file
      IF ( NHMS == 000000 .or. FIRST ) THEN

         !---------------------------
         ! Initialization
         !---------------------------

         ! Strings for directory & filename
         GEOS_DIR = TRIM( MERRA_DIR )
         CN_FILE  = 'YYYYMMDD.cn.' // GET_RES_EXT()

         ! Replace date tokens
         CALL EXPAND_DATE( GEOS_DIR, NYMD, NHMS )
         CALL EXPAND_DATE( CN_FILE,  NYMD, NHMS )

         ! Full file path
         PATH = TRIM( DATA_DIR ) // 
     &          TRIM( GEOS_DIR ) // TRIM( CN_FILE )

         ! Close previously opened CN file
         CLOSE( IU_CN )

         ! Make sure the file unit is valid before we open it 
         IF ( .not. FILE_EXISTS( IU_CN ) ) THEN 
            CALL ERROR_STOP( 'Could not find file!', 
     &                       'OPEN_MERRA_CN_FIELDS (merra_cn_mod.f)' )
         ENDIF

         !---------------------------
         ! Open the CN file
         !---------------------------

         ! Open the file
         OPEN( UNIT   = IU_CN,         FILE   = TRIM( PATH ),
     &         STATUS = 'OLD',         ACCESS = 'SEQUENTIAL',  
     &         FORM   = 'UNFORMATTED', IOSTAT = IOS )
               
         IF ( IOS /= 0 ) THEN
            CALL IOERROR( IOS, IU_CN, 'open_merra_cn_fields:1' )
         ENDIF

         ! Echo info
         WRITE( 6, 100 ) TRIM( PATH )
 100     FORMAT( '     - Opening: ', a )
         
         ! Set the proper first-time-flag false
         FIRST = .FALSE.

         !---------------------------
         ! Get # of fields in file
         !---------------------------

         ! Read the IDENT string
         READ( IU_CN, IOSTAT=IOS ) IDENT

         IF ( IOS /= 0 ) THEN
            CALL IOERROR( IOS, IU_CN, 'open_merra_cn_fields:2' )
         ENDIF
         
         ! The last 2 digits of the ident string
         ! is the # of fields contained in the file
         READ( IDENT(7:8), '(i2.2)' ) N_CN_FIELDS    

      ENDIF

      END SUBROUTINE OPEN_MERRA_CN_FIELDS
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: get_merra_cn_fields
!
! !DESCRIPTION: Subroutine GET\_MERRA\_CN\_FIELDS is a wrapper for routine 
!  READ\_CN.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE GET_MERRA_CN_FIELDS( NYMD, NHMS )
!
! !USES:
!
      USE DAO_MOD, ONLY : FRLAKE     ! Fraction of grid box that is lake
      USE DAO_MOD, ONLY : FRLAND     ! Fraction of grid box that is land
      USE DAO_MOD, ONLY : FRLANDIC   ! Fraction of grid box that is land ice
      USE DAO_MOD, ONLY : FROCEAN    ! Fraction of grid box that is ocean
      USE DAO_MOD, ONLY : PHIS       ! Surface geopotential height
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN) :: NYMD    ! YYYYMMDD date 
      INTEGER, INTENT(IN) :: NHMS    !  and hhmmss time of desired data
! 
! !REVISION HISTORY: 
!  19 Aug 2010 - R. Yantosca - Initial version, based on i6_read_mod.f
!EOP
!------------------------------------------------------------------------------
!BOC
      !=================================================================      
      ! Read data from disk
      !=================================================================
      CALL READ_CN( NYMD     = NYMD,   
     &              NHMS     = NHMS, 
     &              FRLAKE   = FRLAKE, 
     &              FRLAND   = FRLAND, 
     &              FRLANDIC = FRLANDIC, 
     &              FROCEAN  = FROCEAN, 
     &              PHIS     = PHIS      )
      
      END SUBROUTINE GET_MERRA_CN_FIELDS
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: read_cn
!
! !DESCRIPTION: Subroutine READ\_CN reads the MERRA CN (constant) fields
!  from disk.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE READ_CN( NYMD,   NHMS, 
     &                    FRLAKE, FRLAND, FRLANDIC, FROCEAN, PHIS )
!
! !USES:
!
      USE DIAG_MOD,     ONLY : AD67
      USE FILE_MOD,     ONLY : IOERROR
      USE FILE_MOD,     ONLY : IU_CN
      USE TIME_MOD,     ONLY : TIMESTAMP_STRING
      USE TRANSFER_MOD, ONLY : TRANSFER_2D
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN)  :: NYMD   ! YYYYMMDD and
      INTEGER, INTENT(IN)  :: NHMS   !  hhmmss time of desired data
!
! !OUTPUT PARAMETERS:
!
      ! Fraction of grid box covered by lakes [unitless] 
      REAL*8,  INTENT(OUT) :: FRLAKE  (IIPAR,JJPAR)    

      ! Fraction of grid box covered by land ice [unitless]
      REAL*8,  INTENT(OUT) :: FRLAND  (IIPAR,JJPAR)

      ! Fraction of grid box covered by land ice [unitless]
      REAL*8,  INTENT(OUT) :: FRLANDIC(IIPAR,JJPAR)

      ! Fraction of grid box covered by ocean [unitless]
      REAL*8,  INTENT(OUT) :: FROCEAN (IIPAR,JJPAR)

      ! Surface geopotential height [m2/s2]
      REAL*8,  INTENT(OUT) :: PHIS    (IIPAR,JJPAR) 
!
! !REVISION HISTORY: 
!  19 Aug 2010 - R. Yantosca - Initial version, based on i6_read_mod.f
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER            :: IOS, NFOUND, N_CN      
      REAL*4             :: Q2(IGLOB,JGLOB)
      CHARACTER(LEN=8)   :: NAME
      CHARACTER(LEN=16)  :: STAMP
      INTEGER            :: XYMD, XHMS

      !=================================================================
      ! READ_CN begins here!
      !=================================================================

      ! Zero the number of I-6 fields we have already found
      NFOUND = 0

      !=================================================================
      ! Read the CN FIELDS from disk
      !=================================================================
      DO 

         ! I-6 field name
         READ( IU_CN, IOSTAT=IOS ) NAME

         ! IOS < 0: End-of-file, but make sure we have 
         ! found all I-6 fields before exiting loop!
         IF ( IOS < 0 ) THEN
            CALL CN_CHECK( NFOUND, N_CN_FIELDS )
            EXIT
         ENDIF

         ! IOS > 0: True I/O error, stop w/ error msg
         IF ( IOS > 0 ) CALL IOERROR( IOS, IU_CN, 'read_cn:1' )

         ! CASE statement for met fields
         SELECT CASE ( TRIM( NAME ) )

            !-----------------------------------------------
            ! FRLAKE: Fraction of box covered by lakes
            !-----------------------------------------------
            CASE ( 'FRLAKE' )
               READ( IU_CN, IOSTAT=IOS ) XYMD, XHMS, Q2
               IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_CN, 'read_cn:2' )

               IF ( XYMD == NYMD .and. XHMS == NHMS ) THEN
                  CALL TRANSFER_2D( Q2, FRLAKE )
                  NFOUND = NFOUND + 1
               ENDIF

            !-----------------------------------------------
            ! FRLAKE: Fraction of box covered by lakes
            !-----------------------------------------------
            CASE ( 'FRLAND' )
               READ( IU_CN, IOSTAT=IOS ) XYMD, XHMS, Q2
               IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_CN, 'read_cn:3' )

               IF ( XYMD == NYMD .and. XHMS == NHMS ) THEN
                  CALL TRANSFER_2D( Q2, FRLAND )
                  NFOUND = NFOUND + 1
               ENDIF

            !-----------------------------------------------
            ! FRLANDIC: Fraction of box covered by land ice
            !-----------------------------------------------
            CASE ( 'FRLANDIC' )
               READ( IU_CN, IOSTAT=IOS ) XYMD, XHMS, Q2
               IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_CN, 'read_cn:4' )

               IF ( XYMD == NYMD .and. XHMS == NHMS ) THEN
                  CALL TRANSFER_2D( Q2, FRLANDIC )
                  NFOUND = NFOUND + 1
               ENDIF
         
            !-----------------------------------------------
            ! FROCEAN: Fraction of box covered by ocean
            !-----------------------------------------------
            CASE ( 'FROCEAN' )
               READ( IU_CN, IOSTAT=IOS ) XYMD, XHMS, Q2
               IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_CN, 'read_cn:5' )

               IF ( XYMD == NYMD .and. XHMS == NHMS ) THEN
                  CALL TRANSFER_2D( Q2, FROCEAN )
                  NFOUND = NFOUND + 1
               ENDIF

            !-----------------------------------------------
            ! PHIS: Surface geopotential height
            !-----------------------------------------------
            CASE ( 'PHIS' )
               READ( IU_CN, IOSTAT=IOS ) XYMD, XHMS, Q2
               IF ( IOS /= 0 ) CALL IOERROR( IOS, IU_CN, 'read_cn:5' )

               IF ( XYMD == NYMD .and. XHMS == NHMS ) THEN
                  CALL TRANSFER_2D( Q2, PHIS )
                  NFOUND = NFOUND + 1

                  ! Convert from [m2/s2] to [m]
                  PHIS = PHIS / g0
               ENDIF

            !--------------------------------
            ! Field not found
            !--------------------------------
            CASE DEFAULT
               WRITE ( 6, 200 )
               
         END SELECT

         !==============================================================
         ! If we have found all the fields for this time, then exit 
         ! the loop and return to the calling program.  Otherwise, 
         ! go to the next iteration.
         !==============================================================
         IF ( XYMD == NYMD .and. XHMS == NHMS ) THEN
            IF ( NFOUND == N_CN_FIELDS ) THEN
               STAMP = TIMESTAMP_STRING( NYMD, NHMS )
               WRITE( 6, 210 ) NFOUND, STAMP
               EXIT
            ENDIF
         ENDIF
      ENDDO

      ! FORMATs
 200  FORMAT( 'Searching for next CN field!'                          )
 210  FORMAT( '     - Found all ', i3, ' MERRA CN met fields for ', a )

      !=================================================================
      ! ND67 diagnostic: 
      !=================================================================
      IF ( ND67 > 0 ) THEN
         AD67(:,:,15) = AD67(:,:,15) + PHIS  ! Sfc geopotential [m]
      ENDIF

      END SUBROUTINE READ_CN
!EOC
!------------------------------------------------------------------------------
!          Harvard University Atmospheric Chemistry Modeling Group            !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: cn_check
!
! !DESCRIPTION: Subroutine CN\_CHECK prints an error message if not all of 
!  the CN met fields are found.  The run is also terminated.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE CN_CHECK( NFOUND, N_CN )
!
! !USES:
!
      USE ERROR_MOD, ONLY : GEOS_CHEM_STOP
!
! !INPUT PARAMETERS: 
!
      INTEGER, INTENT(IN) :: NFOUND   ! Number of met fields read in from disk
      INTEGER, INTENT(IN) :: N_CN     ! Number of expected met fields
!
! !REVISION HISTORY: 
!  19 Aug 2010 - R. Yantosca - Initial version, based on i6_read_mod.f
!EOP
!------------------------------------------------------------------------------
!BOC
      ! Test if N_FOUND == N_CN
      IF ( NFOUND /= N_CN ) THEN

         ! Write error msg
         WRITE( 6, '(a)' ) REPEAT( '=', 79 )
         WRITE( 6, 100   ) 
         WRITE( 6, 110   ) N_CN, NFOUND
         WRITE( 6, 120   )
         WRITE( 6, '(a)' ) REPEAT( '=', 79 )

         ! FORMATs
 100     FORMAT( 'ERROR -- not enough MERRA CN fields found!' )
 110     FORMAT( 'There are ', i2, ' fields but only ', i2 ,
     &           ' were found!'                               )
 120     FORMAT( '### STOP in CN_CHECK (merra_cn_mod.f)'      )

         ! Deallocate arrays and stop
         CALL GEOS_CHEM_STOP
      ENDIF

      END SUBROUTINE CN_CHECK
!EOC
      END MODULE MERRA_CN_MOD
