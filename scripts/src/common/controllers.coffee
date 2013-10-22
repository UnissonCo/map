module = angular.module('common.controllers', ['http-auth-interceptor', 'ngCookies', 'googleOauth'])

class LoginCtrl
        """
        Login a user
        """
        constructor: (@$scope, @$rootScope, @$http, @Restangular, @$cookies, @authService, @Token) ->
                # set authorization header if already logged in
                if @$cookies.username and @$cookies.key
                        console.debug("Already logged in.")
                        @$http.defaults.headers.common['Authorization'] = "ApiKey #{@$cookies.username}:#{@$cookies.key}"
                        @authService.loginConfirmed()
                @$scope.loginrequired = false

                # On login required
                @$scope.$on('event:auth-loginRequired', =>
                        @$scope.loginrequired = true
                        console.debug("Login required")
                )

                # On login successful
                @$scope.$on('event:auth-loginConfirmed', =>
                        console.debug("Login OK")
                        @$scope.loginrequired = false
                )

                @$scope.accessToken = @Token.get()

                # Add methods to scope
                @$scope.submit = this.submit
                @$scope.authenticateGoogle = this.authenticateGoogle
                @$scope.forceLogin = this.forceLogin

        forceLogin: =>
                @$scope.loginrequired = true

        submit: =>
                console.debug('submitting login...')
                @Restangular.all('account/user').customPOST("login", {}, {},
                                username: @$scope.username
                                password: @$scope.password
                        ).then((data) =>
                                @$cookies.username = data.username
                                @$cookies.key = data.key
                                @$http.defaults.headers.common['Authorization'] = "ApiKey #{data.username}:#{data.key}"
                                @authService.loginConfirmed()
                        , (data) =>
                                console.debug("LoginController submit error: #{data.reason}")
                                @$scope.errorMsg = data.reason
                )

        authenticateGoogle: =>
                extraParams = {}
                if @$scope.askApproval
                        extraParams = {approval_prompt: 'force'}

                @Token.getTokenByPopup(extraParams).then((params) =>
                        # Verify the token before setting it, to avoid the confused deputy problem.
                        console.debug(params)

                        @Restangular.all('account/user/login').customPOST("google", {}, {},
                                access_token: params.access_token
                        ).then((data) =>
                                @$cookies.username = data.username
                                @$cookies.key = data.key
                                @$http.defaults.headers.common['Authorization'] = "ApiKey #{data.username}:#{data.key}"
                                @authService.loginConfirmed()
                        , (data) =>
                                console.debug("LoginController submit error: #{data.reason}")
                                @$scope.errorMsg = data.reason
                        )
                , ->
                        # Failure getting token from popup.
                        alert("Failed to get token from popup.")
                )

LoginCtrl.$inject = ['$scope', '$rootScope', "$http", "Restangular", "$cookies", "authService", "Token"]

module.controller("LoginCtrl", LoginCtrl)