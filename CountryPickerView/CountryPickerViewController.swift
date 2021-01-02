//
//  CountryPickerViewController.swift
//  CountryPickerView
//
//  Created by Kizito Nwose on 18/09/2017.
//  Copyright © 2017 Kizito Nwose. All rights reserved.
//

import UIKit

public class CountryPickerViewController: UITableViewController {

    public var searchController: UISearchController?
    fileprivate var searchResults = [Country]()
    fileprivate var isSearchMode = false
    fileprivate var sectionsTitles = [String]()
    fileprivate var countries = [String: [Country]]()
    fileprivate var hasPreferredSection: Bool {
        return dataSource.preferredCountriesSectionTitle != nil &&
            dataSource.preferredCountries.count > 0
    }
    fileprivate var showOnlyPreferredSection: Bool {
        return dataSource.showOnlyPreferredSection
    }
    internal weak var countryPickerView: CountryPickerView! {
        didSet {
            dataSource = CountryPickerViewDataSourceInternal(view: countryPickerView)
        }
    }
    
    fileprivate var dataSource: CountryPickerViewDataSourceInternal!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        prepareTableItems()
        prepareNavItem()
        prepareSearchBar()
        
        
    }
   
}

// UI Setup
extension CountryPickerViewController {
    
    func prepareTableItems()  {
        if !showOnlyPreferredSection {
            let countriesArray = countryPickerView.usableCountries
            let locale = dataSource.localeForCountryNameInList
            
            var groupedData = Dictionary<String, [Country]>(grouping: countriesArray) {
                let name = $0.localizedName(locale) ?? $0.name
                return String(name.capitalized[name.startIndex])
            }
            groupedData.forEach{ key, value in
                groupedData[key] = value.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.localizedName(locale) ?? lhs.name < rhs.localizedName(locale) ?? rhs.name
                })
            }
            
            countries = groupedData
            sectionsTitles = groupedData.keys.sorted()
        }
        
        // Add preferred section if data is available
        if hasPreferredSection, let preferredTitle = dataSource.preferredCountriesSectionTitle {
            sectionsTitles.insert(preferredTitle, at: sectionsTitles.startIndex)
            countries[preferredTitle] = dataSource.preferredCountries
        }
        
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexTrackingBackgroundColor = .clear
    }
    
    func prepareNavItem() {
        navigationItem.title = dataSource.navigationTitle

        // Add a close button if this is the root view controller
        if navigationController?.viewControllers.count == 1 {
            let closeButton = dataSource.closeButtonNavigationItem
            closeButton.target = self
            closeButton.action = #selector(close)
            navigationItem.leftBarButtonItem = closeButton
        }
        
        navigationController?.navigationBar.barTintColor = dataSource.navBarBackgroundColor
        navigationController?.navigationBar.tintColor = dataSource.navBarTintColor
        navigationController?.navigationBar.titleTextAttributes = nil
        
        
    }
    
    func prepareSearchBar() {
        let searchBarPosition = dataSource.searchBarPosition
        if searchBarPosition == .hidden  {
            return
        }
        searchController = UISearchController(searchResultsController:  nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.hidesNavigationBarDuringPresentation = searchBarPosition == .tableViewHeader
        searchController?.definesPresentationContext = true
        searchController?.searchBar.delegate = self
        searchController?.delegate = self

        switch searchBarPosition {
        case .tableViewHeader: tableView.tableHeaderView = searchController?.searchBar
        case .navigationBar: navigationItem.titleView = searchController?.searchBar
        default: break
        }
    }
    
    @objc private func close() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

//MARK:- UITableViewDataSource
extension CountryPickerViewController {
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return isSearchMode ? 1 : sectionsTitles.count
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchMode ? searchResults.count : countries[sectionsTitles[section]]!.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: CountryTableViewCell.self)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? CountryTableViewCell
            ?? CountryTableViewCell(style: .default, reuseIdentifier: identifier)
        
        let country = isSearchMode ? searchResults[indexPath.row]
            : countries[sectionsTitles[indexPath.section]]![indexPath.row]

//        var name = country.localizedName(dataSource.localeForCountryNameInList) ?? country.name
//        if dataSource.showCountryCodeInList {
//            name = "\(name) (\(country.code))"
//        }
//        if dataSource.showPhoneCodeInList {
//            name = "\(name) (\(country.phoneCode))"
//        }
//        cell.imageView?.image = country.flag
//
//        cell.flgSize = dataSource.cellImageViewSize
//        cell.imageView?.clipsToBounds = true
//
//        cell.imageView?.layer.cornerRadius = dataSource.cellImageViewCornerRadius
//        cell.imageView?.layer.masksToBounds = true
        
        
//        cell.contentView
//        cell.textLabel?.text = name
//        cell.textLabel?.font = dataSource.cellLabelFont
//        if let color = dataSource.cellLabelColor {
//            cell.textLabel?.textColor = color
//        }
        
        let stackView = UIStackView()
        cell.contentView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        cell.accessoryView = nil
        
        cell.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leftAnchor.constraint(equalTo: cell.leftAnchor, constant: 10).isActive = true
        stackView.topAnchor.constraint(equalTo: cell.topAnchor, constant: 10).isActive = true
        stackView.rightAnchor.constraint(equalTo: cell.rightAnchor, constant: -10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -10).isActive = true
        let flagLabel = UILabel()
        flagLabel.font = UIFont.systemFont(ofSize: 30.0)
        flagLabel.text = String.emojiFlagFromCode(capitalCode: country.code)
        let countryNameLabel = UILabel()
        countryNameLabel.text = country.localizedName(dataSource.localeForCountryNameInList) ?? country.name
        countryNameLabel.textColor = dataSource.countryLabelColor
        countryNameLabel.font = dataSource.countryLabelFont
        let countryCodeLabel = UILabel()
        countryCodeLabel.text = "(\(country.phoneCode))"
        countryCodeLabel.textColor = dataSource.countryCodeColor
        countryCodeLabel.font = dataSource.countryCodeFont
        stackView.axis = .horizontal
        stackView.addArrangedSubview(flagLabel)
        stackView.addArrangedSubview(countryNameLabel)
        stackView.addArrangedSubview(countryCodeLabel)
        stackView.addArrangedSubview(UIView())
        stackView.spacing = 16.0
        
        
        let isSelected = country == countryPickerView.selectedCountry
        if isSelected {
            countryNameLabel.textColor = dataSource.selectedCountryLabelColor
            countryCodeLabel.textColor = dataSource.selectedCountryCodeColor
            if dataSource.accessoryView == nil{
                cell.accessoryType = isSelected &&
                    dataSource.showCheckmarkInList ? .checkmark : .none
            }else{
                cell.accessoryView = isSelected ? dataSource.accessoryView : nil
            }
        }
        
        cell.separatorInset = dataSource.seperatorInset
        
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearchMode ? nil : sectionsTitles[section]
    }
    
//    override public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let returnedView = UIView()
//        returnedView.backgroundColor = .green
//
//        let label = UILabel()
//        label.text = sectionsTitles[section]
//        label.sizeToFit()
//        returnedView.addSubview(label)
//
//        return returnedView
//    }
    
    
    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if !dataSource.showIndex {
            return nil
        }
        
        if isSearchMode {
            return nil
        } else {
            if hasPreferredSection {
                return Array<String>(sectionsTitles.dropFirst())
            }
            return sectionsTitles
        }
    }
    
    override public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sectionsTitles.firstIndex(of: title)!
    }
}

//MARK:- UITableViewDelegate
extension CountryPickerViewController {

    override public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = dataSource.sectionTitleLabelFont
            if let color = dataSource.sectionTitleLabelColor {
                header.textLabel?.textColor = color
            }
            if let backgroundColor = dataSource.sectionTitleBackgroundColor{
                header.contentView.backgroundColor = backgroundColor
            }
        }
        

    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = isSearchMode ? searchResults[indexPath.row]
            : countries[sectionsTitles[indexPath.section]]![indexPath.row]

        searchController?.isActive = false
        searchController?.dismiss(animated: false, completion: nil)
        
        let completion = {
            self.countryPickerView.selectedCountry = country
        }
        // If this is root, dismiss, else pop
        if navigationController?.viewControllers.count == 1 {
            navigationController?.dismiss(animated: true, completion: completion)
        } else {
            navigationController?.popViewController(animated: true, completion: completion)
        }
    }
}

// MARK:- UISearchResultsUpdating
extension CountryPickerViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        isSearchMode = false
        if let text = searchController.searchBar.text, text.count > 0 {
            isSearchMode = true
            searchResults.removeAll()
            
            var indexArray = [Country]()
            
            if showOnlyPreferredSection && hasPreferredSection,
                let array = countries[dataSource.preferredCountriesSectionTitle!] {
                indexArray = array
            } else if let array = countries[String(text.capitalized[text.startIndex])] {
                indexArray = array
            }

            searchResults.append(contentsOf: indexArray.filter({
                let name = ($0.localizedName(dataSource.localeForCountryNameInList) ?? $0.name).lowercased()
                let code = $0.code.lowercased()
                let query = text.lowercased()
                return name.hasPrefix(query) || (dataSource.showCountryCodeInList && code.hasPrefix(query))
            }))
        }
        tableView.reloadData()
    }
}

// MARK:- UISearchBarDelegate
extension CountryPickerViewController: UISearchBarDelegate {
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Hide the back/left navigationItem button
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Show the back/left navigationItem button
        prepareNavItem()
        navigationItem.hidesBackButton = false
    }
}

// MARK:- UISearchControllerDelegate
// Fixes an issue where the search bar goes off screen sometimes.
extension CountryPickerViewController: UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        self.navigationController?.navigationBar.isTranslucent = false
    }
}

// MARK:- CountryTableViewCell.
class CountryTableViewCell: UITableViewCell {
    
    /*var flgSize: CGSize = .zero
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView?.frame.size = flgSize
        imageView?.center.y = contentView.center.y
    }*/

}


// MARK:- An internal implementation of the CountryPickerViewDataSource.
// Returns default options where necessary if the data source is not set.
class CountryPickerViewDataSourceInternal: CountryPickerViewDataSource {
    
    private unowned var view: CountryPickerView
    
    init(view: CountryPickerView) {
        self.view = view
    }
    
    var preferredCountries: [Country] {
        return view.dataSource?.preferredCountries(in: view) ?? preferredCountries(in: view)
    }
    
    var preferredCountriesSectionTitle: String? {
        return view.dataSource?.sectionTitleForPreferredCountries(in: view)
    }
    
    var showOnlyPreferredSection: Bool {
        return view.dataSource?.showOnlyPreferredSection(in: view) ?? showOnlyPreferredSection(in: view)
    }
    
    var sectionTitleLabelFont: UIFont {
        return view.dataSource?.sectionTitleLabelFont(in: view) ?? sectionTitleLabelFont(in: view)
    }

    var sectionTitleLabelColor: UIColor? {
        return view.dataSource?.sectionTitleLabelColor(in: view)
    }
    
    var cellLabelFont: UIFont {
        return view.dataSource?.cellLabelFont(in: view) ?? cellLabelFont(in: view)
    }
    
    var cellLabelColor: UIColor? {
        return view.dataSource?.cellLabelColor(in: view)
    }
    
    var cellImageViewSize: CGSize {
        return view.dataSource?.cellImageViewSize(in: view) ?? cellImageViewSize(in: view)
    }
    
    var cellImageViewCornerRadius: CGFloat {
        return view.dataSource?.cellImageViewCornerRadius(in: view) ?? cellImageViewCornerRadius(in: view)
    }
    
    var navigationTitle: String? {
        return view.dataSource?.navigationTitle(in: view)
    }
    
    var closeButtonNavigationItem: UIBarButtonItem {
        guard let button = view.dataSource?.closeButtonNavigationItem(in: view) else {
            return UIBarButtonItem(title: "Close", style: .done, target: nil, action: nil)
        }
        return button
    }
    
    var searchBarPosition: SearchBarPosition {
        return view.dataSource?.searchBarPosition(in: view) ?? searchBarPosition(in: view)
    }
    
    var showPhoneCodeInList: Bool {
        return view.dataSource?.showPhoneCodeInList(in: view) ?? showPhoneCodeInList(in: view)
    }
    
    var showCountryCodeInList: Bool {
        return view.dataSource?.showCountryCodeInList(in: view) ?? showCountryCodeInList(in: view)
    }
    
    var showCheckmarkInList: Bool {
        return view.dataSource?.showCheckmarkInList(in: view) ?? showCheckmarkInList(in: view)
    }
    
    var localeForCountryNameInList: Locale {
        return view.dataSource?.localeForCountryNameInList(in: view) ?? localeForCountryNameInList(in: view)
    }
    
    var excludedCountries: [Country] {
        return view.dataSource?.excludedCountries(in: view) ?? excludedCountries(in: view)
    }
    
    var seperatorInset: UIEdgeInsets {
        return view.dataSource?.seperatorInset(in: view) ?? seperatorInset(in: view)
    }
    
    var accessoryView: UIView?{
        return view.dataSource?.accessoryView(in: view)
    }
    
    var countryLabelFont: UIFont{
        return view.dataSource?.countryLabelFont(in: view) ?? countryLabelFont(in: view)
    }
    
    var countryLabelColor: UIColor{
        return view.dataSource?.countryLabelColor(in: view) ?? countryLabelColor(in: view)
    }
    
    var countryCodeFont: UIFont{
        return view.dataSource?.countryCodeFont(in: view) ?? countryCodeFont(in: view)
    }
    
    var countryCodeColor: UIColor{
        return view.dataSource?.countryCodeColor(in: view) ?? countryCodeColor(in: view)
    }
    
    var selectedCountryLabelColor: UIColor{
        return view.dataSource?.selectedCountryLabelColor(in: view) ?? selectedCountryLabelColor(in: view)
    }
    
    var selectedCountryCodeColor: UIColor{
        return view.dataSource?.selectedCountryCodeColor(in: view) ?? selectedCountryCodeColor(in: view)
    }
    
    var showIndex: Bool{
        return view.dataSource?.showIndex(in: view) ?? showIndex(in: view)
    }
    
    var sectionTitleBackgroundColor: UIColor?{
        return view.dataSource?.sectionTitleBackgroundColor(in: view)
    }
    
    var navBarBackgroundColor: UIColor?{
        return view.dataSource?.navBarTintColor(in: view)
    }
    
    var navBarTintColor: UIColor?{
        return view.dataSource?.navBarTintColor(in: view)
    }
    
    
    

}
