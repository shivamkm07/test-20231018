#See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
ARG BUILD_CONFIGURATION=Release
ENV BUILD_CONFIGURATION=${BUILD_CONFIGURATION}
WORKDIR /src
COPY ["src/HelloDapr.Api/HelloDapr.Api.csproj", "src/HelloDapr.Api/"]
RUN dotnet restore "src/HelloDapr.Api/HelloDapr.Api.csproj"
COPY . .
WORKDIR "/src/src/HelloDapr.Api"
RUN dotnet build "HelloDapr.Api.csproj" -c ${BUILD_CONFIGURATION} -o /app/build

FROM build AS publish
ARG VERSION
ENV Version=${VERSION}
RUN dotnet publish "HelloDapr.Api.csproj" -c ${BUILD_CONFIGURATION} -o /app/publish /p:UseAppHost=false /p:Version=${Version:-$(date "+%y.%m%d.%H%M")}

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "HelloDapr.Api.dll"]
